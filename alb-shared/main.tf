# Shared ALB of this account in this region (ADR-001), with its ACM certificate validated through
# Cloudflare DNS. It only accepts HTTPS from Cloudflare's IP ranges: the WAF cannot be bypassed.

locals {
  env_short   = { "shared-services" = "shr", staging = "stg", production = "prd" }[var.environment]
  base        = "jonomait-${local.env_short}"
  cert_domain = "*.${var.zone}"
}

data "aws_vpc" "main" {
  tags = { Name = "${local.base}-network" }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = { Tier = "public" }
}

data "cloudflare_zone" "main" {
  filter = {
    name = var.zone
  }
}

# Cloudflare's published ranges, refreshed on every plan: a change on their side shows up as a
# security group update in the next plan.
data "cloudflare_ip_ranges" "main" {}

# ---------------------------------------------------------------- certificate
resource "aws_acm_certificate" "main" {
  domain_name       = local.cert_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# ACM asks for the same validation record for a name in every region of an account, so only the
# primary region creates it (create_validation_records = true); the other regions reuse it.
# Not proxied: behind the proxy the CNAME would answer with Cloudflare addresses and never validate.
# Keyed by the certificate name (known at plan time), not by the validation options (known only
# after the certificate exists).
resource "cloudflare_dns_record" "validation" {
  for_each = var.create_validation_records ? toset([local.cert_domain]) : toset([])

  zone_id = data.cloudflare_zone.main.id
  name    = trimsuffix(local.validation[each.key].resource_record_name, ".")
  type    = local.validation[each.key].resource_record_type
  content = trimsuffix(local.validation[each.key].resource_record_value, ".")
  ttl     = 60
  proxied = false
  comment = "ACM validation, ${var.environment} (managed by Terraform)"
}

locals {
  validation = { for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => dvo }
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for dvo in aws_acm_certificate.main.domain_validation_options : trimsuffix(dvo.resource_record_name, ".")]

  depends_on = [cloudflare_dns_record.validation]
}

# ------------------------------------------------------------------------ ALB
module "alb" {
  source = "git::https://github.com/JonomaIT/terraform-modules.git//alb?ref=v0.6.0"

  name                = "${local.base}-alb-shared"
  vpc_id              = data.aws_vpc.main.id
  subnets             = data.aws_subnets.public.ids
  certificate_arn     = aws_acm_certificate_validation.main.certificate_arn
  ingress_cidrs       = data.cloudflare_ip_ranges.main.ipv4_cidrs
  deletion_protection = var.deletion_protection
}
