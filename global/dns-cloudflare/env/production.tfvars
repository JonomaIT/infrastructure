environment = "production"
regions     = ["us-east-1", "sa-east-1"] # two regions: Cloudflare Load Balancing on ingress.<zone>; the same as global/platform
# The zone is the platform's: global/platform/env/production.tfvars.

# Both regions take traffic and process what is created in them (ADR-013). Failover: list the
# failed region in out (one PR); back to active-passive: remove mode.
mode = "active-active"
out  = []

# App names are not listed here: each app creates its own name, pointing to the ingress, when it
# is deployed (ADR-010).
