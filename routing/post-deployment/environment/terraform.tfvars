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

# No public domain in AWS yet: the accelerator is reached through its own DNS name / static IPs.
# route53_hosted_zone = "Z0000000000000"
# dns_name            = "app.example.com"
