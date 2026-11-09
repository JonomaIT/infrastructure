environment = "production"
zone        = "joshuel.com.br"
regions     = ["us-east-1", "sa-east-1"] # the same as global/dns-cloudflare

# Zones with an owner: the platform zone's apex (the personal site) and each customer's domain.
# Only that app may have names there; the site issues its own certificate.
zone_owners = {
  "joshuel.com.br"         = "web-joshuel"     # the apex; <label>.joshuel.com.br stays open to every app
  "draleticiapenin.com.br" = "web-dra-leticia" # customer site
}

# Lab: the whole account is torn down after each test, app data included. A real production keeps
# the default (false): tables keep deletion protection and buckets with objects are never removed.
allow_destroy_app_data = true
