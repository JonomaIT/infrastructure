# Plans the component against each account tfvars with mocked providers (no credentials):
#   for f in $(find env -name "*.tfvars"); do terraform test -var-file="$f"; done

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

mock_provider "aws" {
  alias = "secondary"

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
    condition = (
      length(var.regions) == 1
      ? length(cloudflare_dns_record.ingress) == 1 && length(cloudflare_load_balancer.ingress) == 0
      : length(cloudflare_load_balancer.ingress) == 1 && length(cloudflare_load_balancer_pool.region) == 2 && length(cloudflare_dns_record.ingress) == 0
    )
    error_message = "One region: the ingress is a CNAME. Two regions: the ingress is a load balancer with one pool per region."
  }

  assert {
    condition     = startswith(output.ingress, "ingress")
    error_message = "The entry of the environment is ingress.<zone> (production) or ingress-<env>.<zone>."
  }
}
