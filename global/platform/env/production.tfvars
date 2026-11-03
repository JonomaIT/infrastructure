environment = "production"
zone        = "joshuel.com.br"
regions     = ["us-east-1", "sa-east-1"] # the same as global/dns-cloudflare

# Customer sites with their own domain (cloudfront-site issues their certificate).
site_zones = ["draleticiapenin.com.br"]

# Lab: the whole account is torn down after each test, app data included. A real production keeps
# the default (false): tables keep deletion protection and buckets with objects are never removed.
allow_destroy_app_data = true
