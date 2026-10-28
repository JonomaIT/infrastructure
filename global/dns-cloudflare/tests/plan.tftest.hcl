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

  assert {
    condition = (
      aws_ssm_parameter.region_state[var.regions[0]].insecure_value == "ACTIVE" &&
      length([for p in aws_ssm_parameter.region_state : p if p.insecure_value == "ACTIVE"]) == length(local.active_regions) &&
      aws_ssm_parameter.region_state[var.regions[0]].name == "/jonomait/${var.environment}/platform/region-state"
    )
    error_message = "The ACTIVE regions are the first of the failover order (ADR-012) or all in service (ADR-013)."
  }
}

run "active_passive" {
  command = plan

  variables {
    regions = ["us-east-1", "sa-east-1"]
    mode    = "active-passive"
  }

  assert {
    condition = (
      cloudflare_load_balancer.ingress[0].steering_policy == "off" &&
      aws_ssm_parameter.region_state["us-east-1"].insecure_value == "ACTIVE" &&
      aws_ssm_parameter.region_state["sa-east-1"].insecure_value == "PASSIVE" &&
      aws_ssm_parameter.platform["sa-east-1/active-regions"].insecure_value == "us-east-1"
    )
    error_message = "Active/passive: failover in order, only the first region ACTIVE."
  }
}

run "active_active" {
  command = plan

  variables {
    regions = ["us-east-1", "sa-east-1"]
    mode    = "active-active"
  }

  assert {
    condition = (
      cloudflare_load_balancer.ingress[0].steering_policy == "random" &&
      length(cloudflare_load_balancer.ingress[0].default_pools) == 2 &&
      cloudflare_load_balancer.ingress[0].session_affinity == "ip_cookie" &&
      alltrue([for p in aws_ssm_parameter.region_state : p.insecure_value == "ACTIVE"]) &&
      aws_ssm_parameter.platform["us-east-1/active-regions"].insecure_value == "us-east-1,sa-east-1"
    )
    error_message = "Active/active: both regions take traffic (random, sticky per client) and both are ACTIVE."
  }
}

run "active_active_with_a_region_out" {
  command = plan

  variables {
    regions = ["us-east-1", "sa-east-1"]
    mode    = "active-active"
    out     = ["us-east-1"]
  }

  assert {
    condition = (
      length(cloudflare_load_balancer.ingress[0].default_pools) == 1 &&
      aws_ssm_parameter.region_state["us-east-1"].insecure_value == "PASSIVE" &&
      aws_ssm_parameter.region_state["sa-east-1"].insecure_value == "ACTIVE" &&
      aws_ssm_parameter.platform["sa-east-1/active-regions"].insecure_value == "sa-east-1"
    )
    error_message = "A region out gets no traffic and turns PASSIVE; the other one takes its copies."
  }
}

run "out_needs_active_active" {
  command = plan

  variables {
    regions = ["us-east-1", "sa-east-1"]
    mode    = "active-passive"
    out     = ["sa-east-1"]
  }

  expect_failures = [var.out]
}

run "every_region_out_is_refused" {
  command = plan

  variables {
    regions = ["us-east-1", "sa-east-1"]
    mode    = "active-active"
    out     = ["us-east-1", "sa-east-1"]
  }

  expect_failures = [var.out]
}

run "platform_parameters" {
  command = plan

  assert {
    condition = (
      length(aws_ssm_parameter.platform) == 4 * length(var.regions) &&
      aws_ssm_parameter.platform["${var.regions[0]}/zone"].insecure_value == var.zone &&
      aws_ssm_parameter.platform["${var.regions[0]}/regions"].insecure_value == join(",", var.regions) &&
      aws_ssm_parameter.platform["${var.regions[0]}/allow-destroy"].name == "/jonomait/${var.environment}/platform/allow-destroy"
    )
    error_message = "zone, regions, allow-destroy and active-regions are published in every region, for the runners and apps to read (ADR-014)."
  }
}
