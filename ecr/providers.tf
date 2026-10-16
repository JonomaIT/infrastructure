provider "aws" {
  region = var.region

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "ecr"
      "jonomait:managed-by" = "terraform"
    }
  }
}
