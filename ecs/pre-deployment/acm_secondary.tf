resource "aws_acm_certificate" "secondary" {
  provider = aws.secondary

  domain_name               = var.acm_dns_certs[0]
  subject_alternative_names = slice(var.acm_dns_certs, 1, length(var.acm_dns_certs))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Reuses the primary validation records (same CNAME per name across regions).
resource "aws_acm_certificate_validation" "secondary" {
  provider = aws.secondary

  certificate_arn         = aws_acm_certificate.secondary.arn
  validation_record_fqdns = [for r in cloudflare_record.cert_validation : r.hostname]

  lifecycle {
    # Fail fast instead of waiting ~45 min for a validation that can never happen.
    precondition {
      condition = (
        toset(aws_acm_certificate.secondary.domain_validation_options[*].resource_record_name) ==
        toset(aws_acm_certificate.main.domain_validation_options[*].resource_record_name)
      )
      error_message = "The secondary certificate asks for different validation records than the primary one; add records for it in acm_secondary.tf."
    }
  }
}
