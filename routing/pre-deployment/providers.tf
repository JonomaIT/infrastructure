provider "aws" {
  region = var.region
}

# Token read from CLOUDFLARE_API_TOKEN (needs Zone Settings: Edit for this component).
provider "cloudflare" {}
