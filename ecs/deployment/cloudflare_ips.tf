# Cloudflare's published IP ranges (public endpoint, no token). Read on every plan, so a change
# on Cloudflare's side shows up as a rule update in the next plan.
data "http" "cloudflare_ips" {
  count = var.cloudflare_only ? 1 : 0

  url = "https://api.cloudflare.com/client/v4/ips"

  request_headers = {
    Accept = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200 && try(jsondecode(self.response_body).success, false)
      error_message = "Could not read Cloudflare's IP ranges; refusing to plan security group rules from an empty list."
    }
  }
}
