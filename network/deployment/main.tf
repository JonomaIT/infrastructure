module "vpc" {

  source = "git::https://github.com/JonomaIT/terraform-modules.git//vpc?ref=v0.3.1"

  project_name = var.project_name

  cidr = var.cidr

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

}
