module "cluster" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//cluster-ecs?ref=v0.4.0"

  project_name = var.project_name

  vpc_id          = data.aws_ssm_parameter.vpc.value
  public_subnets  = data.aws_ssm_parameter.public_subnets[*].value
  private_subnets = data.aws_ssm_parameter.private_subnets[*].value

  # HTTPS on the internal ALB and the NLB (Global Accelerator 443), with the certificate
  # issued by ecs/pre-deployment in this same region.
  acm_certs = data.aws_ssm_parameter.acm_certs[*].value

  # Only Cloudflare reaches the NLB and the internal ALB (plus the VPC CIDR, always allowed by the
  # module). With the public name proxied, this closes every path around Cloudflare, including
  # the accelerator's own DNS name and IPs.
  ingress_cidrs = var.cloudflare_only ? jsondecode(data.http.cloudflare_ips[0].response_body).result.ipv4_cidrs : ["0.0.0.0/0"]

  # The internet-facing ALB would be a second public entry point that bypasses Cloudflare.
  external_lb_enabled = var.external_lb_enabled
}
