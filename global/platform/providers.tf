provider "aws" {
  region = var.regions[0]

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "global/platform"
      "jonomait:managed-by" = "terraform"
    }
  }
}
