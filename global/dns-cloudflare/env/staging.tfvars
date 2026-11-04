environment = "staging"
regions     = ["us-east-1"] # one region: ingress-stg.<zone> is a proxied CNAME to the ALB
# The zone is the platform's: global/platform/env/staging.tfvars.

# App names are not listed here: each app creates its own name, pointing to the ingress, when it
# is deployed (ADR-010).
