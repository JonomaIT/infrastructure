# infrastructure

JonomaIT platform infrastructure in Terraform: what the infra team operates in the platform accounts (`shared-services`, `staging`, `production`), on which the apps run. Modules come from [`terraform-modules`](https://github.com/JonomaIT/terraform-modules), always pinned by tag.

## Components

| Component | Type | Runs in | Creates |
|---|---|---|---|
| `network` | regional | staging, production | VPC `jonomait-<env>-network`: private /20 and public /24 per AZ, NAT |
| `ecs-cluster` | regional | staging, production | Cluster `jonomait-<env>-ecs` and the `jonomait.internal` namespace |
| `alb-shared` | regional | staging, production | ACM `*.<zone>` validated through Cloudflare + ALB `jonomait-<env>-alb-shared`, HTTPS only, only from Cloudflare |
| `global/cloudflare-zone` | global | shared-services | Zone settings: Full (strict), Always Use HTTPS, TLS 1.2+, TLS 1.3 |
| `global/dns-cloudflare` | global | staging, production | Public names: proxied CNAME (one region) or Cloudflare Load Balancing with failover (two regions) |
| `cross-region/network-peering` | cross-region | production | Peering between the two VPCs, routes on both sides |

`<env>` is `stg`, `prd` or `shr`. Apps are not here: they are deployed by the ECS runner in [`pipelines`](https://github.com/JonomaIT/pipelines) with the [`ecs-service`](https://github.com/JonomaIT/terraform-modules/tree/main/ecs-service) pattern.

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

## Running (by hand, until the deploy pipeline exists)

```bash
aws sso login --sso-session jonomait
export AWS_PROFILE=jonomait-staging
export CLOUDFLARE_API_TOKEN=...   # only for components that use Cloudflare

cd network
terraform init -reconfigure \
  -backend-config=../backends/staging.tfbackend \
  -backend-config=key=staging/us-east-1/network
terraform plan -var-file=env/staging/us-east-1.tfvars
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

`ci.yml` runs on every pull request: `terraform fmt`, then for every component `validate` and its `terraform test` against **each** tfvars, with mocked providers (no credentials). The tests check the conventions: NAT count, cluster and namespace names, validation record only in the primary region, zone in Full (strict), CNAME vs load balancer by number of regions, peering routes on every route table.

The previous lab (`network`, `ecs` and `routing` stacks with Global Accelerator) is kept in the **`lab-v1`** tag.

## Costs

Bill while they exist: NAT Gateway (one per VPC in the lab), the ALB, Fargate tasks and, with two regions, Cloudflare Load Balancing. Destroy in reverse order when done testing: `dns-cloudflare` → `network-peering` → `alb-shared` → `ecs-cluster` → `network`.
