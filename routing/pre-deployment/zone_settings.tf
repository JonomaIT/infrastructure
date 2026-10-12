data "cloudflare_zone" "main" {
  name = var.cloudflare_zone
}

# Zone-wide TLS settings, owned by Terraform. The zone serves only this project, so it can own them.
# Only the settings listed here are managed; removing this resource restores the values the zone
# had before Terraform took over.
resource "cloudflare_zone_settings_override" "main" {
  zone_id = data.cloudflare_zone.main.id

  settings {
    # Cloudflare → origin over HTTPS, validating the origin certificate (ACM *.joshuel.com.br).
    ssl = "strict"

    # Visitor HTTP → 301 to HTTPS at the edge: plain HTTP never reaches the origin.
    always_use_https = "on"

    # http:// links inside HTML responses are rewritten to https:// when possible.
    automatic_https_rewrites = "on"

    # Visitors: TLS 1.2 minimum, TLS 1.3 enabled.
    min_tls_version = "1.2"
    tls_1_3         = "on"
  }
}
