provider "aws" {
  region = var.region

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "alb-shared"
      "jonomait:managed-by" = "terraform"
    }
  }
}

# Token read from CLOUDFLARE_API_TOKEN, so it never goes through tfvars or the state.
provider "cloudflare" {}
