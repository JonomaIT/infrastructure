# Optional public name for the accelerator. Only created when a hosted zone and a name are given.
resource "aws_route53_record" "main" {
  count = var.route53_hosted_zone != null && var.dns_name != null ? 1 : 0

  zone_id = var.route53_hosted_zone
  name    = var.dns_name
  type    = "CNAME"
  ttl     = 60

  records = [aws_globalaccelerator_accelerator.main.dns_name]
}
