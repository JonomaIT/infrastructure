provider "aws" {
  region = var.regions[0]

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "cross-region/network-peering"
      "jonomait:managed-by" = "terraform"
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = var.regions[1]

  default_tags {
    tags = {
      "jonomait:env"        = var.environment
      "jonomait:app"        = "plataforma"
      "jonomait:repo"       = "infrastructure"
      "jonomait:component"  = "cross-region/network-peering"
      "jonomait:managed-by" = "terraform"
    }
  }
}
