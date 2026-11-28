# ECS cluster of this account in this region and the <prefix>.internal namespace (app ↔ app).

locals {
  env_short = { "shared-services" = "shr", staging = "stg", production = "prd" }[var.environment]
  base      = "${var.prefix}-${local.env_short}"
}

data "aws_vpc" "main" {
  tags = { Name = "${local.base}-network" }
}

module "ecs_cluster" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//ecs-cluster?ref=v0.16.0"

  name               = "${local.base}-ecs"
  vpc_id             = data.aws_vpc.main.id
  namespace          = "${var.prefix}.internal"
  container_insights = var.container_insights
}
