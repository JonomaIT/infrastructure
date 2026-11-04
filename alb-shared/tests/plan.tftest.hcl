# Plans the component against each account tfvars with mocked providers (no credentials):
#   for f in $(find env -name "*.tfvars"); do terraform test -var-file="$f"; done

# PROJECT_PREFIX org variable (TF_VAR_prefix in the pipeline).
variables {
  prefix = "jonomait"
}

mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = { id = "vpc-12345678", cidr_block = "10.10.0.0/16" }
  }
  mock_data "aws_subnets" {
    defaults = { ids = ["subnet-1", "subnet-2"] }
  }
  mock_data "aws_route_tables" {
    defaults = { ids = ["rtb-1", "rtb-2", "rtb-3"] }
  }
  mock_data "aws_lb" {
    defaults = { dns_name = "jonomait-alb-shared-1.us-east-1.elb.amazonaws.com" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_data "aws_ssm_parameter" {
    defaults = { insecure_value = "joshuel.com.br" }
  }
  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:us-east-1:111111111111:certificate/test"
      domain_validation_options = [{
        domain_name           = "*.joshuel.com.br"
        resource_record_name  = "_abc.joshuel.com.br."
        resource_record_type  = "CNAME"
        resource_record_value = "_def.acm-validations.aws."
      }]
    }
  }
}

mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = { id = "zone123", account = { id = "account123" } }
  }
  mock_data "cloudflare_ip_ranges" {
    defaults = { ipv4_cidrs = ["173.245.48.0/20", "103.21.244.0/22"] }
  }
}

run "plan" {
  command = plan

  assert {
    condition     = length(cloudflare_dns_record.validation) == (var.create_validation_records ? 1 : 0)
    error_message = "Only the primary region creates the validation record."
  }
}

run "zone_comes_from_the_platform" {
  command = plan

  assert {
    condition     = aws_acm_certificate.main.domain_name == "*.joshuel.com.br" && endswith(local.ingress_host, ".joshuel.com.br")
    error_message = "The certificate and the ingress use the platform's zone (global/platform), not a tfvars of this component."
  }
}
