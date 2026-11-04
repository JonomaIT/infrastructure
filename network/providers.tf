provider "aws" {
  region = var.region

  default_tags {
    tags = {
      "${var.prefix}:env"        = var.environment
      "${var.prefix}:app"        = "plataforma"
      "${var.prefix}:repo"       = "infrastructure"
      "${var.prefix}:component"  = "network"
      "${var.prefix}:managed-by" = "terraform"
    }
  }
}
