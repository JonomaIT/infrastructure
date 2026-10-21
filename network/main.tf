# VPC of this account in this region. Subnets are computed from the CIDR, so a tfvars only says
# the range and the AZs: a /20 private subnet per AZ from the start of the range, and a /24 public
# subnet per AZ right after them (x.x.48.0, x.x.49.0, x.x.50.0).

locals {
  env_short = { "shared-services" = "shr", staging = "stg", production = "prd" }[var.environment]
  name      = "jonomait-${local.env_short}-network"
}

module "vpc" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=v0.9.0"

  project_name       = local.name
  cidr               = var.cidr
  single_nat_gateway = var.single_nat_gateway

  private_subnets = [
    for i, az in var.azs : { name = "${local.name}-private-${az}", cidr = cidrsubnet(var.cidr, 4, i), availability_zone = az }
  ]

  public_subnets = [
    for i, az in var.azs : { name = "${local.name}-public-${az}", cidr = cidrsubnet(var.cidr, 8, 48 + i), availability_zone = az }
  ]
}
