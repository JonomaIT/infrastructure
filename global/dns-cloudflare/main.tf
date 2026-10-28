# Entry of the environment (ADR-009, ADR-010): one public name per account, owned by the platform.
# Apps never get a name here: each app creates its own proxied CNAME to this entry when it is
# deployed (app-dns pattern), and the shared ALB routes its host to it.
#   one region  → ingress is a proxied CNAME to the shared ALB of that region
#   two regions → ingress is a Cloudflare Load Balancer: one pool per region (that region's ALB),
#                 a monitor on the ALB's /health (the region, not an app) and
#                   active-passive: failover in the order of var.regions (steering off)
#                   active-active:  every region in service, traffic split at random (included in
#                                   the base Load Balancing plan; geo or proximity need the paid
#                                   Traffic Steering add-on), each client kept on one region

locals {
  env_short = { "shared-services" = "shr", staging = "stg", production = "prd" }[var.environment]
  alb_name  = "jonomait-${local.env_short}-alb-shared"
  multi     = length(var.regions) > 1

  # Pools that take traffic: every region in failover order, or the regions in service.
  serving = var.mode == "active-active" ? [for r in var.regions : r if !contains(var.out, r)] : var.regions

  # Same convention as alb-shared, whose /health answers on this host.
  ingress = var.environment == "production" ? "ingress.${var.zone}" : "ingress-${local.env_short}.${var.zone}"

  alb_dns = merge(
    { (var.regions[0]) = data.aws_lb.primary.dns_name },
    local.multi ? { (var.regions[1]) = data.aws_lb.secondary[0].dns_name } : {},
  )
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
resource "cloudflare_dns_record" "ingress" {
  count = local.multi ? 0 : 1

  zone_id = data.cloudflare_zone.main.id
  name    = local.ingress
  type    = "CNAME"
  content = local.alb_dns[var.regions[0]]
  proxied = true
  ttl     = 1 # automatic; mandatory when proxied
  comment = "owner: platform, ${var.environment} entry (managed by Terraform)"
}

# --------------------------------------------------------------- two regions
resource "cloudflare_load_balancer_monitor" "ingress" {
  count = local.multi ? 1 : 0

  account_id     = data.cloudflare_zone.main.account.id
  description    = "${local.ingress} region health"
  type           = "https"
  method         = "GET"
  path           = "/health"
  expected_codes = "200"
  interval       = 60
  timeout        = 5
  retries        = 2

  # The ALB answers /health only for the ingress host (alb module, priority 1).
  header = {
    Host = [local.ingress]
  }
}

resource "cloudflare_load_balancer_pool" "region" {
  for_each = local.multi ? toset(var.regions) : toset([])

  account_id  = data.cloudflare_zone.main.account.id
  name        = replace("jonomait-${local.env_short}-${each.value}", ".", "-")
  description = "${var.environment} shared ALB in ${each.value}"
  monitor     = cloudflare_load_balancer_monitor.ingress[0].id

  origins = [{
    name    = each.value
    address = local.alb_dns[each.value]
    enabled = true
  }]
}

resource "cloudflare_load_balancer" "ingress" {
  count = local.multi ? 1 : 0

  zone_id     = data.cloudflare_zone.main.id
  name        = local.ingress
  description = "${var.environment} entry, ${var.mode}: ${join(var.mode == "active-active" ? " + " : " → ", local.serving)} (managed by Terraform)"
  proxied     = true

  # off = failover: always the first healthy pool, in this order. random = active/active: any
  # healthy pool, equal weights; an unhealthy pool is skipped either way.
  steering_policy = var.mode == "active-active" ? "random" : "off"
  default_pools   = [for region in local.serving : cloudflare_load_balancer_pool.region[region].id]
  fallback_pool   = cloudflare_load_balancer_pool.region[local.serving[length(local.serving) - 1]].id

  # active-active: a client stays on one region (cookie, or its IP when it sends no cookie, as the
  # API calls of a site do), so it reads its own writes before the global tables replicate them.
  session_affinity     = var.mode == "active-active" ? "ip_cookie" : "none"
  session_affinity_ttl = var.mode == "active-active" ? 1800 : null
}
