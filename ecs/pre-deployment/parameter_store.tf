# Each region publishes its own certificate ARN under the same name, so ecs/deployment reads
# /<project_name>/acm/arn in whatever region it runs. The value comes from the validation
# resource: the parameter only exists once the certificate is issued.
resource "aws_ssm_parameter" "acm_arn" {
  type  = "String"
  name  = format("/%s/acm/arn", var.project_name)
  value = aws_acm_certificate_validation.main.certificate_arn
}

resource "aws_ssm_parameter" "acm_arn_secondary" {
  provider = aws.secondary

  type  = "String"
  name  = format("/%s/acm/arn", var.project_name)
  value = aws_acm_certificate_validation.secondary.certificate_arn
}
