data "aws_ssm_parameter" "vpc" {
  name = var.ssm_vpc_id
}

data "aws_ssm_parameter" "public_subnets" {
  count = length(var.ssm_public_subnets)
  name  = var.ssm_public_subnets[count.index]
}

data "aws_ssm_parameter" "private_subnets" {
  count = length(var.ssm_private_subnets)
  name  = var.ssm_private_subnets[count.index]
}

# Certificates published by ecs/pre-deployment (one per region, same parameter name).
data "aws_ssm_parameter" "acm_certs" {
  count = length(var.ssm_acm_certs)
  name  = var.ssm_acm_certs[count.index]
}
