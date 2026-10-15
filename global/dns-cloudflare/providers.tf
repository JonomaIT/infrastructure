provider "aws" {
  region = var.regions[0]

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "global/dns-cloudflare"
      "jonomait:managed-by" = "terraform"
    }
  }
}

# Secondary region (same as the primary when there is only one; then it is not used).
provider "aws" {
  alias  = "secondary"
  region = var.regions[length(var.regions) - 1]

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "global/dns-cloudflare"
      "jonomait:managed-by" = "terraform"
    }
  }
}

# Token read from CLOUDFLARE_API_TOKEN, so it never goes through tfvars or the state.
provider "cloudflare" {}
