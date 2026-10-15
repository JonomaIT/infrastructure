# Zone-wide settings of the Cloudflare zone, owned by Terraform. Runs once, from shared-services
# (the zone is shared by every account). Records and load balancers live in dns-cloudflare, per account.

data "cloudflare_zone" "main" {
  filter = {
    name = var.zone
  }
}

locals {
  settings = {
    ssl                      = "strict" # Cloudflare → origin over HTTPS, validating the ACM certificate
    always_use_https         = "on"     # visitor HTTP → 301 to HTTPS at the edge
    automatic_https_rewrites = "on"     # http:// links in HTML rewritten to https:// when possible
    min_tls_version          = "1.2"    # visitors: TLS 1.2 minimum
    tls_1_3                  = "on"
  }
}

resource "cloudflare_zone_setting" "main" {
  for_each = local.settings

  zone_id    = data.cloudflare_zone.main.id
  setting_id = each.key
  value      = each.value
}
