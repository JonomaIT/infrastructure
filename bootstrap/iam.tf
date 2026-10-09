# Role que o GitHub Actions do repo assume via OIDC. Nome por convenção: github-actions-<repo>,
# então o workflow monta o ARN sozinho, sem variável por repo.
resource "aws_iam_role" "github_actions" {
  name               = "github-actions-${var.github_repo}"
  description        = "Assumida via OIDC pelo GitHub Actions de ${var.github_org}/${var.github_repo}"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  max_session_duration = 3600
}

# VPC, subnets, NAT, EIP, rotas e peering
resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# State no S3 e parâmetros SSM do projeto
resource "aws_iam_role_policy" "pipeline" {
  name   = "terraform-pipeline"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.pipeline.json
}

# Stack ecs (cluster, load balancers, Cloud Map, Route 53 privado e VPC Link)
resource "aws_iam_role_policy" "ecs" {
  name   = "terraform-ecs"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.ecs.json
}
