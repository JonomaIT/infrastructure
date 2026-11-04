provider "aws" {
  region = var.regions[0]

  default_tags {
    tags = {
      "${var.prefix}:env"        = var.environment
      "${var.prefix}:app"        = "plataforma"
      "${var.prefix}:repo"       = "infrastructure"
      "${var.prefix}:component"  = "global/platform"
      "${var.prefix}:managed-by" = "terraform"
    }
  }
}
