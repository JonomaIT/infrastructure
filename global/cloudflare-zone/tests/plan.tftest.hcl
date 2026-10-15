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
    condition     = cloudflare_zone_setting.main["ssl"].value == "strict" && cloudflare_zone_setting.main["always_use_https"].value == "on"
    error_message = "The zone must use Full (strict) and always redirect to HTTPS."
  }
}
