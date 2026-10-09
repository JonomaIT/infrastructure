module "cluster" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//cluster-ecs?ref=v0.2.0"

  project_name = var.project_name

  vpc_id          = data.aws_ssm_parameter.vpc.value
  public_subnets  = data.aws_ssm_parameter.public_subnets[*].value
  private_subnets = data.aws_ssm_parameter.private_subnets[*].value
}
