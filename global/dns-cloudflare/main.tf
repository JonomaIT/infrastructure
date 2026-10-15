# Public names of this account's apps (ADR-002, ADR-009). A new public name is a PR here.
#   one region  → proxied CNAME to the shared ALB of that region
#   two regions → Cloudflare Load Balancing: an HTTPS monitor per name, one pool per region
#                 (each pointing at that region's ALB) and failover in the order of var.regions

locals {
  env_short = { "shared-services" = "shr", staging = "stg", production = "prd" }[var.environment]
  alb_name  = "jonomait-${local.env_short}-alb-shared"
  multi     = length(var.regions) > 1

  fqdn = { for name, r in var.records : name => "${name}.${var.zone}" }

  alb_dns = merge(
    { (var.regions[0]) = data.aws_lb.primary.dns_name },
    local.multi ? { (var.regions[1]) = data.aws_lb.secondary[0].dns_name } : {},
  )

  # One pool per (name, region): "hello/us-east-1"
  pools = local.multi ? {
    for pair in setproduct(keys(var.records), var.regions) : "${pair[0]}/${pair[1]}" => { name = pair[0], region = pair[1] }
  } : {}
}

data "cloudflare_zone" "main" {
  filter = {
    name = var.zone
  }
}

data "aws_lb" "primary" {
  name = local.alb_name
}

data "aws_lb" "secondary" {
  count    = local.multi ? 1 : 0
  provider = aws.secondary
  name     = local.alb_name
}

# ----------------------------------------------------------------- one region
resource "cloudflare_dns_record" "app" {
  for_each = local.multi ? {} : var.records

  zone_id = data.cloudflare_zone.main.id
  name    = local.fqdn[each.key]
  type    = "CNAME"
  content = local.alb_dns[var.regions[0]]
  proxied = true
  ttl     = 1 # automatic; mandatory when proxied
  comment = "${var.environment} shared ALB (managed by Terraform)"
}

# --------------------------------------------------------------- two regions
resource "cloudflare_load_balancer_monitor" "app" {
  for_each = local.multi ? var.records : {}

  account_id     = data.cloudflare_zone.main.account.id
  description    = local.fqdn[each.key]
  type           = "https"
  method         = "GET"
  path           = each.value.health_check_path
  expected_codes = "200"
  interval       = 60
  timeout        = 5
  retries        = 2

  # The ALB routes by host name: without this header the check would hit the default 404.
  header = {
    Host = [local.fqdn[each.key]]
  }
}

resource "cloudflare_load_balancer_pool" "app" {
  for_each = local.pools

  account_id  = data.cloudflare_zone.main.account.id
  name        = replace("jonomait-${local.env_short}-${each.value.name}-${each.value.region}", ".", "-")
  description = "${local.fqdn[each.value.name]} in ${each.value.region}"
  monitor     = cloudflare_load_balancer_monitor.app[each.value.name].id

  origins = [{
    name    = each.value.region
    address = local.alb_dns[each.value.region]
    enabled = true
  }]
}

resource "cloudflare_load_balancer" "app" {
  for_each = local.multi ? var.records : {}

  zone_id     = data.cloudflare_zone.main.id
  name        = local.fqdn[each.key]
  description = "${var.environment}: ${join(" → ", var.regions)} (managed by Terraform)"
  proxied     = true

  # steering off = failover: always the first healthy pool, in this order.
  steering_policy = "off"
  default_pools   = [for region in var.regions : cloudflare_load_balancer_pool.app["${each.key}/${region}"].id]
  fallback_pool   = cloudflare_load_balancer_pool.app["${each.key}/${var.regions[length(var.regions) - 1]}"].id
}
