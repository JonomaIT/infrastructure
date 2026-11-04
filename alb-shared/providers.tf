provider "aws" {
  region = var.region

  default_tags {
    tags = {
      "${var.prefix}:env"        = var.environment
      "${var.prefix}:app"        = "plataforma"
      "${var.prefix}:repo"       = "infrastructure"
      "${var.prefix}:component"  = "alb-shared"
      "${var.prefix}:managed-by" = "terraform"
    }
  }
}

# Token read from CLOUDFLARE_API_TOKEN, so it never goes through tfvars or the state.
provider "cloudflare" {}
