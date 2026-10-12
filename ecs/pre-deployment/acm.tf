data "cloudflare_zone" "main" {
  name = var.cloudflare_zone
}

# ACM is regional: the same certificate is requested in each region (see acm_secondary.tf).
resource "aws_acm_certificate" "main" {
  domain_name               = var.acm_dns_certs[0]
  subject_alternative_names = slice(var.acm_dns_certs, 1, length(var.acm_dns_certs))
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# One validation record per name. ACM uses the same CNAME for a name in every region of the
# account, so these records validate the secondary certificate too (checked there).
# Not proxied: behind the Cloudflare proxy the CNAME would answer with Cloudflare addresses
# and ACM would never validate.
resource "cloudflare_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.cloudflare_zone.main.id
  name    = trimsuffix(each.value.name, ".")
  type    = each.value.type
  content = trimsuffix(each.value.value, ".")
  ttl     = 60
  proxied = false
  comment = format("ACM validation for %s (managed by Terraform)", var.project_name)
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for r in cloudflare_record.cert_validation : r.hostname]
}
