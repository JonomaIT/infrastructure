# infrastructure

Infraestrutura da JonomaIT em Terraform: uma rede em duas regiões (`us-east-1` e `sa-east-1`) ligadas por peering, e um cluster ECS em cada região. Os módulos vêm de [`terraform-modules`](https://github.com/JonomaIT/terraform-modules), sempre por tag.

## Stacks

```
network/                      ecs/
├── pre-deployment            ├── pre-deployment
├── deployment                ├── deployment       ← cluster-ecs?ref=v0.2.0
│   └── environment/          │   └── environment/
│       ├── us-east-1/        │       ├── us-east-1/
│       └── sa-east-1/        │       └── sa-east-1/
└── post-deployment (peering) └── post-deployment
bootstrap/                    ← role do GitHub Actions (aplicado à mão)
```

| Stack | O que cria | Publica no SSM | Lê do SSM |
|---|---|---|---|
| `network` | VPC, subnets, NAT por AZ, peering entre as regiões com rotas | `/jonomait-multiregion/vpc/...` | — |
| `ecs` | Cluster ECS, ALB externo, ALB interno, zona `jonomait-ecs.internal`, Cloud Map, VPC Link | `/jonomait-ecs/...` | `/jonomait-multiregion/vpc/...` |

Uma stack nunca lê o state da outra: tudo o que é compartilhado passa pelo SSM, por convenção de nome.

Cada componente tem um state próprio no bucket `jonomait-statefiles`, com lock nativo do S3. A região é argumento, não pasta: o mesmo `deployment/` roda com `environment/<região>/`.

## Pipeline

| Workflow | Quando | O que faz |
|---|---|---|
| `Infrastructure` | PR para `main` | `plan` só das stacks afetadas (mudar `network` também planeja `ecs`) |
| `Infrastructure` | push na `main` | `plan` + `apply` do plan salvo, em todas as stacks: network → ecs |
| `Infrastructure` | manual | escolhe `all` ou `ecs` |
| `Destroy` | manual | ver abaixo |

- Autenticação na AWS por **OIDC**, sem access key. A role é `github-actions-<repo>`, criada pelo `bootstrap`.
- O apply aplica exatamente o plan gerado no mesmo job.
- Actions fixadas por SHA; versão do Terraform pela variável da org `TERRAFORM_VERSION`.
- Variáveis da org usadas: `AWS_ACCOUNT_ID`, `AWS_REGION`, `TERRAFORM_VERSION`.

## Bootstrap

A role da pipeline não tem permissão de IAM, de propósito: o `bootstrap/` é aplicado à mão, por alguém com acesso administrativo.

```bash
cd bootstrap
terraform init -backend-config=environment/backend.tfvars
terraform apply -var-file=environment/terraform.tfvars
```

Stack nova que grava no SSM ou usa serviço novo = permissão nova aqui antes do primeiro run.

## Destroy

`Actions → Destroy → Run workflow`, a partir da `main`:

1. `stack`: `ecs` (só o cluster) ou `all` (cluster e rede).
2. `confirm`: digite `destroy`.
3. Aprove o job **Approve destroy** (Environment `destroy`, com revisor obrigatório).

Ordem: `ecs` antes de `network` (os load balancers e o VPC Link ocupam as subnets) e, dentro de cada stack, `post → sa-east-1 → us-east-1 → pre`. O `bootstrap` nunca é destruído pela pipeline.

Para subir tudo de novo: `Actions → Infrastructure → Run workflow`.

## Rodando localmente

```bash
cd network/deployment
terraform init -reconfigure -backend-config=environment/us-east-1/backend.tfvars
terraform plan -var-file=environment/us-east-1/terraform.tfvars
```

`-reconfigure` é obrigatório ao trocar de região no mesmo diretório: sem ele o `plan` usa o state da região anterior.

## Custos

Ficam cobrando enquanto existem: NAT Gateways (3 por região), os 3 load balancers do ECS por região e o Container Insights. Para pausar o lab, use o `Destroy`.
