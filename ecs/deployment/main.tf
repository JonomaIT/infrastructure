module "cluster" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//cluster-ecs?ref=v0.3.1"

  project_name = var.project_name

  vpc_id          = data.aws_ssm_parameter.vpc.value
  public_subnets  = data.aws_ssm_parameter.public_subnets[*].value
  private_subnets = data.aws_ssm_parameter.private_subnets[*].value

  # HTTPS on the internal ALB and the NLB (Global Accelerator 443), with the certificate
  # issued by ecs/pre-deployment in this same region.
  acm_certs = data.aws_ssm_parameter.acm_certs[*].value
}
