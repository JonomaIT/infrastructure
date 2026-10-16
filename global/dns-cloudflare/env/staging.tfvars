environment = "staging"
zone        = "joshuel.com.br"
regions     = ["us-east-1"] # one region: ingress-stg.<zone> is a proxied CNAME to the ALB

# App names are not listed here: each app creates its own name, pointing to the ingress, when it
# is deployed (ADR-010).
