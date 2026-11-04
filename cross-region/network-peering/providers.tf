provider "aws" {
  region = var.regions[0]

  default_tags {
    tags = {
      "${var.prefix}:env"        = var.environment
      "${var.prefix}:app"        = "plataforma"
      "${var.prefix}:repo"       = "infrastructure"
      "${var.prefix}:component"  = "cross-region/network-peering"
      "${var.prefix}:managed-by" = "terraform"
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.regions[1]

  default_tags {
    tags = {
      "${var.prefix}:env"        = var.environment
      "${var.prefix}:app"        = "plataforma"
      "${var.prefix}:repo"       = "infrastructure"
      "${var.prefix}:component"  = "cross-region/network-peering"
      "${var.prefix}:managed-by" = "terraform"
    }
  }
}
