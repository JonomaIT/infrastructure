project_name     = "jonomait-routing"
region_primary   = "us-east-1"
region_secondary = "sa-east-1"

nlb_arn_primary_ssm   = "/jonomait-ecs/vpc-link/nlb-arn"
nlb_arn_secondary_ssm = "/jonomait-ecs/vpc-link/nlb-arn"

# Active-passive: all traffic to us-east-1. Move the dial to fail over or split traffic.
routing = {
  primary   = 100
  secondary = 0
}

# Public name in Cloudflare (DNS only, see cloudflare.tf). Covered by the *.joshuel.com.br certificate.
cloudflare_zone = "joshuel.com.br"
dns_name        = "multiregion.joshuel.com.br"
