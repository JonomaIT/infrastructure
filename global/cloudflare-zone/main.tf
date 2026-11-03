# Zone-wide settings of the Cloudflare zones, owned by Terraform: the platform's zone and the
# customer zones of global/platform (site_zones). Runs once, from shared-services (the zones are
# shared by every account). Records and load balancers live in dns-cloudflare and in the apps.
#
# Persistent: a destroy of everything leaves it (terraform-deploy persistent). Without these
# settings a zone falls back to Cloudflare's defaults, and a site behind it could stop working.
# The zones themselves are created in the Cloudflare dashboard (they hold the nameservers given to
# the registrar); this only reads them.

data "cloudflare_zone" "main" {
  for_each = toset(var.zones)

  filter = {
    name = each.value
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
  for_each = { for pair in setproduct(var.zones, keys(local.settings)) : "${pair[0]}/${pair[1]}" => { zone = pair[0], setting = pair[1] } }

  zone_id    = data.cloudflare_zone.main[each.value.zone].id
  setting_id = each.value.setting
  value      = local.settings[each.value.setting]
}

# Before the second zone, the settings were keyed by name only.
moved {
  from = cloudflare_zone_setting.main["ssl"]
  to   = cloudflare_zone_setting.main["joshuel.com.br/ssl"]
}

moved {
  from = cloudflare_zone_setting.main["always_use_https"]
  to   = cloudflare_zone_setting.main["joshuel.com.br/always_use_https"]
}

moved {
  from = cloudflare_zone_setting.main["automatic_https_rewrites"]
  to   = cloudflare_zone_setting.main["joshuel.com.br/automatic_https_rewrites"]
}

moved {
  from = cloudflare_zone_setting.main["min_tls_version"]
  to   = cloudflare_zone_setting.main["joshuel.com.br/min_tls_version"]
}

moved {
  from = cloudflare_zone_setting.main["tls_1_3"]
  to   = cloudflare_zone_setting.main["joshuel.com.br/tls_1_3"]
}
