# Peering between this account's VPCs in the primary and secondary regions, with routes on both
# sides. Runs after network in both regions (VPCs found by the Name tag jonomait-<env>-network).

locals {
  env_short = { "shared-services" = "shr", staging = "stg", production = "prd" }[var.environment]
  vpc_name  = "jonomait-${local.env_short}-network"
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "primary" {
  tags = { Name = local.vpc_name }
}

data "aws_vpc" "secondary" {
  provider = aws.secondary
  tags     = { Name = local.vpc_name }
}

data "aws_route_tables" "primary" {
  vpc_id = data.aws_vpc.primary.id
}

data "aws_route_tables" "secondary" {
  provider = aws.secondary
  vpc_id   = data.aws_vpc.secondary.id
}

resource "aws_vpc_peering_connection" "main" {
  vpc_id        = data.aws_vpc.primary.id
  peer_vpc_id   = data.aws_vpc.secondary.id
  peer_owner_id = data.aws_caller_identity.current.account_id
  peer_region   = var.regions[1]
  auto_accept   = false

  tags = {
    Name = "${local.vpc_name}-${var.regions[0]}-${var.regions[1]}"
    Side = "requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "main" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
  auto_accept               = true

  tags = {
    Name = "${local.vpc_name}-${var.regions[0]}-${var.regions[1]}"
    Side = "accepter"
  }
}

# Names in the other VPC (e.g. its jonomait.internal services) resolve to private addresses.
resource "aws_vpc_peering_connection_options" "requester" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.main.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_vpc_peering_connection_options" "accepter" {
  provider                  = aws.secondary
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.main.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# A peering creates no routes by itself: every route table of each VPC sends the other range
# through it. The accepter's ID makes the routes wait until the peering is active.
resource "aws_route" "to_secondary" {
  for_each = toset(data.aws_route_tables.primary.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.main.id
}

resource "aws_route" "to_primary" {
  provider = aws.secondary
  for_each = toset(data.aws_route_tables.secondary.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.primary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.main.id
}
