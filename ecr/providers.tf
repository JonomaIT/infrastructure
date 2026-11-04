provider "aws" {
  region = var.region

  default_tags {
    tags = {
      "${var.prefix}:env"        = var.environment
      "${var.prefix}:app"        = "plataforma"
      "${var.prefix}:repo"       = "infrastructure"
      "${var.prefix}:component"  = "ecr"
      "${var.prefix}:managed-by" = "terraform"
    }
  }
}
