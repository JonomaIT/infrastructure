data "cloudflare_zone" "main" {
  name = var.cloudflare_zone
}

# Public name for the accelerator.
# - proxied = false (default): DNS only. Clients talk straight to the accelerator's anycast IPs,
#   so failover and the traffic dial behave exactly as configured in Global Accelerator.
# - proxied = true: Cloudflare (WAF, cache, DDoS) in front of the accelerator. Requires the
#   zone SSL mode to be Full (strict) for HTTPS to the origin.
resource "cloudflare_record" "main" {
  zone_id = data.cloudflare_zone.main.id
  name    = var.dns_name
  type    = "CNAME"
  content = aws_globalaccelerator_accelerator.main.dns_name
  proxied = var.cloudflare_proxied
  ttl     = var.cloudflare_proxied ? 1 : 60 # 1 = automatic, mandatory when proxied
  comment = format("Global Accelerator %s (managed by Terraform)", var.project_name)
}
