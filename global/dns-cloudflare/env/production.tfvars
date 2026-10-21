environment = "production"
zone        = "joshuel.com.br"
regions     = ["sa-east-1", "us-east-1"] # FAILOVER (game day 20/10): sa-east-1 ACTIVE and first in the load balancer

# App names are not listed here: each app creates its own name, pointing to the ingress, when it
# is deployed (ADR-010).
