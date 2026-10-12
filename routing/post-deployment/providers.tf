provider "aws" {
  region = var.region_primary
}

provider "aws" {
  alias  = "secondary"
  region = var.region_secondary
}
# Token read from CLOUDFLARE_API_TOKEN, so it never goes through tfvars or the state.
provider "cloudflare" {}
