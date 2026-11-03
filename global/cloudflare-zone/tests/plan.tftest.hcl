# Plans the component against each account tfvars with mocked providers (no credentials):
#   for f in $(find env -name "*.tfvars"); do terraform test -var-file="$f"; done

mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = { id = "zone123", account = { id = "account123" } }
  }
  mock_data "cloudflare_ip_ranges" {
    defaults = { ipv4_cidrs = ["173.245.48.0/20", "103.21.244.0/22"] }
  }
}

run "plan" {
  command = plan

  assert {
    condition = alltrue(flatten([
      for z in var.zones : [
        cloudflare_zone_setting.main["${z}/ssl"].value == "strict",
        cloudflare_zone_setting.main["${z}/always_use_https"].value == "on",
        cloudflare_zone_setting.browser_cache_ttl[z].value == 0,
      ]
    ]))
    error_message = "Every zone must use Full (strict), always redirect to HTTPS and respect the origin's cache headers."
  }
}
