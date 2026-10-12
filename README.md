# infrastructure

JonomaIT infrastructure in Terraform: a network in two regions (`us-east-1` and `sa-east-1`) connected by peering, and an ECS cluster in each region. Modules come from [`terraform-modules`](https://github.com/JonomaIT/terraform-modules), always pinned by tag.

## Stacks

```
network/                      ecs/
├── pre-deployment            ├── pre-deployment
├── deployment                ├── deployment       ← cluster-ecs?ref=v0.2.0
│   └── environment/          │   └── environment/
│       ├── us-east-1/        │       ├── us-east-1/
│       └── sa-east-1/        │       └── sa-east-1/
└── post-deployment (peering) └── post-deployment
bootstrap/                    ← GitHub Actions role (applied manually)
```

| Stack | Creates | Publishes to SSM | Reads from SSM |
|---|---|---|---|
| `network` | VPC, subnets, one NAT per AZ, cross-region peering with routes | `/jonomait-multiregion/vpc/...` | — |
| `ecs` | ECS cluster, external ALB, internal ALB, `jonomait-ecs.internal` zone, Cloud Map, VPC Link | `/jonomait-ecs/...` | `/jonomait-multiregion/vpc/...` |

A stack never reads another stack's state: everything shared goes through SSM, by naming convention.

Each component has its own state in the `jonomait-statefiles` bucket, with native S3 locking. The region is an argument, not a folder: the same `deployment/` runs with `environment/<region>/`.

## Pipeline

| Workflow | When | What it does |
|---|---|---|
| `Infrastructure` | PR to `main` | `plan` for the affected stacks only (a `network` change also plans `ecs`) |
| `Infrastructure` | push to `main` | `plan` + `apply` of the saved plan for every stack: network → ecs |
| `Infrastructure` | manual | choose `all` or `ecs` |
| `Destroy` | manual | see below |

- AWS authentication through **OIDC**, no access keys. The role is `github-actions-<repo>`, created by `bootstrap`.
- The apply runs exactly the plan generated in the same job.
- Actions pinned by SHA; Terraform version from the `TERRAFORM_VERSION` org variable.
- Org variables used: `AWS_ACCOUNT_ID`, `AWS_REGION`, `TERRAFORM_VERSION`.

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

1. `stack`: `ecs` (cluster only) or `all` (cluster and network).
2. `confirm`: type `destroy`.
3. Approve the **Approve destroy** job (`destroy` Environment, with a required reviewer).

Order: `ecs` before `network` (load balancers and the VPC Link sit in the subnets) and, within each stack, `post → sa-east-1 → us-east-1 → pre`. `bootstrap` is never destroyed by the pipeline.

To bring everything back up: `Actions → Infrastructure → Run workflow`.

## Running locally

```bash
cd network/deployment
terraform init -reconfigure -backend-config=environment/us-east-1/backend.tfvars
terraform plan -var-file=environment/us-east-1/terraform.tfvars
```

`-reconfigure` is required when switching regions in the same directory: without it, `plan` uses the previous region's state.

## Costs

These keep billing while they exist: NAT Gateways (3 per region), the 3 ECS load balancers per region and Container Insights. To pause the lab, use `Destroy`.
