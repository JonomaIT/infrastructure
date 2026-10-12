# infrastructure

JonomaIT infrastructure in Terraform: a network in two regions (`us-east-1` and `sa-east-1`) connected by peering, an ECS cluster in each region, and a Global Accelerator routing traffic between them. Modules come from [`terraform-modules`](https://github.com/JonomaIT/terraform-modules), always pinned by tag.

## Stacks

```
network/                      ecs/                          routing/
├── pre-deployment            ├── pre-deployment            ├── pre-deployment
├── deployment  ← vpc         ├── deployment  ← cluster-ecs └── post-deployment (Global Accelerator)
│   └── environment/          │   └── environment/
│       ├── us-east-1/        │       ├── us-east-1/
│       └── sa-east-1/        │       └── sa-east-1/
└── post-deployment (peering) └── post-deployment
bootstrap/                    ← GitHub Actions role (applied manually)
```

| Stack | Creates | Publishes to SSM | Reads from SSM |
|---|---|---|---|
| `network` | VPC, subnets, one NAT per AZ, cross-region peering with routes | `/jonomait-multiregion/vpc/...` | — |
| `ecs` | `pre-deployment`: ACM `*.joshuel.com.br` in both regions, validated through Cloudflare DNS. `deployment`: ECS cluster, external ALB, internal ALB (HTTP + HTTPS), `jonomait-ecs.internal` zone, Cloud Map, internal NLB + VPC Link | `/jonomait-ecs/...` (incl. `/jonomait-ecs/acm/arn` per region) | `/jonomait-multiregion/vpc/...` |
| `routing` | Global Accelerator (2 static anycast IPs) with one endpoint group per region pointing at the ecs NLB, and the public name `multiregion.joshuel.com.br` in Cloudflare | — | `/jonomait-ecs/vpc-link/nlb-arn` (both regions) |

A stack never reads another stack's state: everything shared goes through SSM, by naming convention.

Each component has its own state in the `jonomait-statefiles` bucket, with native S3 locking. The region is an argument, not a folder: the same `deployment/` runs with `environment/<region>/`.

## Pipeline

| Workflow | When | What it does |
|---|---|---|
| `Infrastructure` | PR to `main` | `plan` for the affected stacks and everything downstream (network → ecs → routing) |
| `Infrastructure` | push to `main` | `plan` + `apply` of the saved plan for every stack: network → ecs → routing |
| `Infrastructure` | manual | choose where to start: `all`, `ecs` or `routing` (downstream stacks always run) |
| `Destroy` | manual | see below |

- AWS authentication through **OIDC**, no access keys. The role is `github-actions-<repo>`, created by `bootstrap`.
- The apply runs exactly the plan generated in the same job.
- Actions pinned by SHA; Terraform version from the `TERRAFORM_VERSION` org variable.
- Org variables used: `AWS_ACCOUNT_ID`, `AWS_REGION`, `TERRAFORM_VERSION`.
- Org secret used: `CLOUDFLARE_API_TOKEN_JONOMA` (Cloudflare `Zone:Read` + `DNS:Edit` on `joshuel.com.br`), passed only to `ecs/pre-deployment` and `routing/post-deployment` as `CLOUDFLARE_API_TOKEN`.

## Bootstrap

The pipeline role has no IAM permissions on purpose: `bootstrap/` is applied manually, by someone with administrative access.

```bash
cd bootstrap
terraform init -backend-config=environment/backend.tfvars
terraform apply -var-file=environment/terraform.tfvars
```

A new stack that writes to SSM or uses a new AWS service needs its permissions added here before its first run.

## Destroy

`Actions → Destroy → Run workflow`, from `main`:

1. `stack`: `routing` (Global Accelerator only), `ecs` (routing + cluster) or `all` (everything).
2. `confirm`: type `destroy`.
3. Approve the **Approve destroy** job (`destroy` Environment, with a required reviewer).

Order: `routing → ecs → network` (Global Accelerator points at the ecs NLBs; load balancers and the VPC Link sit in the network subnets) and, within each stack, `post → regions → pre`. `bootstrap` is never destroyed by the pipeline.

To bring everything back up: `Actions → Infrastructure → Run workflow`.

## Traffic routing

`routing/post-deployment/environment/terraform.tfvars` sets the traffic dial per region:

```hcl
routing = {
  primary   = 100 # us-east-1
  secondary = 0   # sa-east-1
}
```

`100/0` is active-passive. To fail over, swap it to `0/100` and apply; `50/50` splits traffic (active-active). Until a service is deployed, each ALB answers `200` with `jonomait-ecs - <region>`, so `curl https://multiregion.joshuel.com.br` shows which region served the request.

## Cloudflare

`ecs/pre-deployment` (certificate validation records) and `routing/post-deployment` (public CNAME) use the Cloudflare provider. It reads the token from `CLOUDFLARE_API_TOKEN`, so the token never goes through tfvars or the state. Locally, export it before running those two components:

```bash
export CLOUDFLARE_API_TOKEN='...'
```

The public record is DNS only (`cloudflare_proxied = false`): clients reach the accelerator directly, so failover follows the traffic dial. Setting it to `true` puts Cloudflare's proxy (WAF, cache) in front and requires the zone SSL mode to be Full (strict).

## Running locally

```bash
cd network/deployment
terraform init -reconfigure -backend-config=environment/us-east-1/backend.tfvars
terraform plan -var-file=environment/us-east-1/terraform.tfvars
```

`-reconfigure` is required when switching regions in the same directory: without it, `plan` uses the previous region's state.

## Costs

These keep billing while they exist: NAT Gateways (3 per region), the 3 ECS load balancers per region, Container Insights and the Global Accelerator (fixed hourly fee plus data transfer premium). To pause the lab, use `Destroy` (`routing` alone removes just the accelerator).
