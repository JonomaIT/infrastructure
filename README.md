# infrastructure

JonomaIT platform infrastructure in Terraform: what the infra team operates in the platform accounts (`shared-services`, `staging`, `production`), on which the apps run. Modules come from [`terraform-modules`](https://github.com/JonomaIT/terraform-modules), always pinned by tag.

## Components

| Component | Type | Runs in | Creates |
|---|---|---|---|
| `ecr` | regional | shared-services | App image repositories (immutable tags, scan on push), pull for the whole organization, replicated to the other regions |
| `network` | regional | staging, production | VPC `jonomait-<env>-network`: private /20 and public /24 per AZ, NAT, S3 and DynamoDB gateway endpoints |
| `ecs-cluster` | regional | staging, production | Cluster `jonomait-<env>-ecs` and the `jonomait.internal` namespace |
| `alb-shared` | regional | staging, production | ACM `*.<zone>` validated through Cloudflare + ALB `jonomait-<env>-alb-shared`, HTTPS only, only from Cloudflare |
| `global/cloudflare-zone` | global | shared-services | Zone settings: Full (strict), Always Use HTTPS, TLS 1.2+, TLS 1.3 |
| `global/dns-cloudflare` | global | staging, production | The environment's entry (`ingress`): proxied CNAME (one region) or Cloudflare Load Balancing (two regions: failover, or active-active with `mode`), and the **region state** (`/jonomait/<env>/platform/region-state` and `active-regions`: in active-passive the first region of `regions` is `ACTIVE`, ADR-012; in active-active every region not in `out`, ADR-013) |
| `cross-region/network-peering` | cross-region | production | Peering between the two VPCs, routes on both sides |

`<env>` is `stg`, `prd` or `shr`. Apps are not here: they are deployed by the ECS runner in [`pipelines`](https://github.com/JonomaIT/pipelines) with the [`ecs-service`](https://github.com/JonomaIT/terraform-modules/tree/main/ecs-service) pattern, and their data (tables, topics, queues, buckets) by the data runner, from the app's own `deploy/data.hcl` (ADR-011). A new app with an image only needs its repository name in `ecr`.

### Failover of the processing (ADR-012, ADR-013)

Cloudflare moves the **traffic** by itself when a region fails its health check. The **processing** (workers that only consume while their region is `ACTIVE`) moves when the order of `regions` in `global/dns-cloudflare/env/<account>.tfvars` changes: one PR, one apply, both the load balancer order and the region state flip together. The passive region's queues keep every message meanwhile (fan-out across regions), so nothing is lost; idempotency avoids processing twice.

**Active/active** (`mode = "active-active"`, ADR-013): both regions take traffic (random steering, included in the base Load Balancing plan; each client sticks to one region) and both are `ACTIVE`. Each worker processes the messages created in its own region; the copies from the other region wait in its standby queue. **Failover:** list the failed region in `out` (one PR): it leaves the load balancer, turns `PASSIVE` and leaves `active-regions`, and the remaining region's workers take its copies. Remove it from `out` to bring it back.

```
infrastructure/
├── backends/<account>.tfbackend        state bucket of each account
├── network/                            REGIONAL
│   └── env/<account>/<region>.tfvars
├── ecs-cluster/  alb-shared/           REGIONAL (same layout)
├── global/
│   ├── cloudflare-zone/env/shared-services.tfvars
│   └── dns-cloudflare/env/<account>.tfvars
└── cross-region/
    └── network-peering/env/<account>.tfvars
```

A component never reads another component's state: it finds what it needs **by name or tag** (VPC `Name = jonomait-<env>-network`, subnets `Tier = public | private`, ALB `jonomait-<env>-alb-shared`). The CIDRs follow the plan in the platform docs (`10.10/16` staging, `10.20/16` and `10.120/16` production).

### Order

```
network → ecs-cluster → alb-shared        (each region; regions are independent)
       → cross-region/network-peering     (after both regions)
       → global/dns-cloudflare            (after the ALBs exist)
global/cloudflare-zone                    (any time, once)
```

A new region is **a new tfvars file** in `network`, `ecs-cluster` and `alb-shared`, plus its name in `regions` of `dns-cloudflare`. No code changes.

## Deploy (pipeline)

The logic lives in [`pipelines`](https://github.com/JonomaIT/pipelines) (`terraform-deploy`); `.github/workflows/deploy.yml` only says when to run it and the apply order.

| When | What happens |
|---|---|
| pull request | plan of what changed (read-only role), posted as a PR comment; `Plan result` must pass |
| merge to `main` | plan → **one approval per account** looking at the plans (run summary) → apply of those plans |
| *Actions → Deploy → Run workflow* | the same for a component, a tfvars or everything; **`destroy`** tears it down in reverse order |
| every night | drift check: changes in what is deployed open the *Terraform drift detected* issue |

Bringing the lab up or down is one manual run (empty target), with `destroy` off or on.

### By hand (debugging)

```bash
aws sso login --sso-session jonomait --use-device-code
export AWS_PROFILE=jonomait-production
source ~/.config/jonomait/cloudflare.env   # only for components that use Cloudflare

cd network
terraform init -reconfigure   -backend-config=../backends/production.tfbackend   -backend-config=key=production/us-east-1/network
terraform plan -var-file=env/production/us-east-1.tfvars
```

State key: `<account>/<region>/<component>` for regional components, `<account>/global/<component>` and `<account>/cross-region/<component>` for the others (from `global/dns-cloudflare`, the key ends in `dns-cloudflare`). `-reconfigure` is required when switching account or region in the same directory.

### Cloudflare token

Read from `CLOUDFLARE_API_TOKEN`, never from tfvars or the state. Permissions on the zone:

| Permission | Used by |
|---|---|
| Zone: Zone Read, DNS Edit | `alb-shared` (ACM validation), `dns-cloudflare` |
| Zone: Zone Settings Edit | `cloudflare-zone` |
| Zone: Load Balancers Edit · Account: Load Balancing: Monitors and Pools Edit | `dns-cloudflare` with two regions |

Cloudflare Load Balancing is a paid add-on (about US$ 5/month with 2 origins): enable it in the dashboard before applying `dns-cloudflare` with two regions.

## Access

The pipeline roles are created in each account by the `bootstrap` of the [`organization`](https://github.com/JonomaIT/organization) repo (whoever uses an access does not control it): pull requests assume `github-actions-infrastructure-plan` (read-only), apply jobs assume `github-actions-infrastructure` and must declare the GitHub Environment of the account.

## CI

`ci.yml` calls `terraform-ci` from `pipelines` on every pull request: `terraform fmt`, then for every component `validate` and its `terraform test` against **each** tfvars, with mocked providers (no credentials), plus the security scan (gitleaks, TFLint, Trivy). The tests check the conventions: NAT count, cluster and namespace names, validation record only in the primary region, zone in Full (strict), CNAME vs load balancer by number of regions, peering routes on every route table.

The previous lab (`network`, `ecs` and `routing` stacks with Global Accelerator) is kept in the **`lab-v1`** tag.

## Costs

Bill while they exist: NAT Gateway (one per VPC in the lab), the ALB, Fargate tasks and, with two regions, Cloudflare Load Balancing. Destroy in reverse order when done testing: `dns-cloudflare` → `network-peering` → `alb-shared` → `ecs-cluster` → `network`.
