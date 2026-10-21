environment = "production"
zone        = "joshuel.com.br"
regions     = ["us-east-1", "sa-east-1"] # two regions: Cloudflare Load Balancing on ingress.<zone>, failover in this order

# App names are not listed here: each app creates its own name, pointing to the ingress, when it
# is deployed (ADR-010).
