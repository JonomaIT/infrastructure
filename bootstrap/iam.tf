# Role assumed by this repo's GitHub Actions through OIDC. Named by convention, github-actions-<repo>,
# so the workflow builds the ARN on its own, without a per-repo variable.
resource "aws_iam_role" "github_actions" {
  name               = "github-actions-${var.github_repo}"
  description        = "Assumed through OIDC by GitHub Actions of ${var.github_org}/${var.github_repo}"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  max_session_duration = 3600
}

# VPC, subnets, NAT, EIP, routes and peering
resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

# S3 state and the project's SSM parameters
resource "aws_iam_role_policy" "pipeline" {
  name   = "terraform-pipeline"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.pipeline.json
}

# ecs stack (cluster, load balancers, Cloud Map, private Route 53 and VPC Link)
resource "aws_iam_role_policy" "ecs" {
  name   = "terraform-ecs"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.ecs.json
}
