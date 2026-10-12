output "acm_arn" {
  description = "Certificate ARN in the primary region"
  value       = aws_acm_certificate_validation.main.certificate_arn
}

output "acm_arn_secondary" {
  description = "Certificate ARN in the secondary region"
  value       = aws_acm_certificate_validation.secondary.certificate_arn
}

output "validation_records" {
  description = "Validation records created in Cloudflare"
  value       = [for r in cloudflare_record.cert_validation : r.hostname]
}
