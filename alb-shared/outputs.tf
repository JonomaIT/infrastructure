output "alb_name" {
  description = "Shared ALB (apps and dns-cloudflare find it by the name jonomait-<env>-alb-shared)"
  value       = "${local.base}-alb-shared"
}

output "alb_dns_name" {
  description = "Origin Cloudflare points to"
  value       = module.alb.dns_name
}

output "certificate_arn" {
  description = "Validated ACM certificate (*.<zone>)"
  value       = aws_acm_certificate_validation.main.certificate_arn
}
