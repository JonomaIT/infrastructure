environment = "production"
zone        = "joshuel.com.br"
regions     = ["us-east-1", "sa-east-1"] # two regions: Cloudflare Load Balancing on ingress.<zone>, failover in this order

# App names are not listed here: each app creates its own name, pointing to the ingress, when it
# is deployed (ADR-010).

# Lab: the whole account is torn down after each test, app data included. A real production keeps
# the default (false): tables keep deletion protection and buckets with objects are never removed.
allow_destroy_app_data = true
