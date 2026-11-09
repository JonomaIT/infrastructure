# Plans the component against each account tfvars with a mocked provider (no credentials):
#   for f in env/*.tfvars; do terraform test -var-file="$f"; done

# PROJECT_PREFIX org variable (TF_VAR_prefix in the pipeline).
variables {
  prefix = "jonomait"
}

mock_provider "aws" {}

run "published_in_every_region" {
  command = plan

  assert {
    condition = (
      aws_ssm_parameter.platform["${var.regions[0]}/zone"].insecure_value == var.zone &&
      aws_ssm_parameter.platform["${var.regions[0]}/regions"].insecure_value == join(",", var.regions) &&
      aws_ssm_parameter.platform["${var.regions[0]}/allow-destroy"].name == "/${var.prefix}/${var.environment}/platform/allow-destroy" &&
      length(aws_ssm_parameter.platform) == length(local.parameters) * length(var.regions)
    )
    error_message = "zone, regions and allow-destroy (and site-zones, when set) are published in every region, for the runners to read (ADR-014)."
  }
}

run "site_zones_only_when_set" {
  command = plan

  variables {
    zone_owners = {}
  }

  assert {
    condition     = !contains(keys(local.parameters), "site-zones") && !contains(keys(local.parameters), "zone-owners")
    error_message = "No customer zone: no site-zones parameter (SSM does not take an empty value)."
  }
}

run "customer_zone" {
  command = plan

  variables {
    regions     = ["us-east-1", "sa-east-1"]
    zone_owners = { "joshuel.com.br" = "web-joshuel", "cliente.com.br" = "web-cliente" }
  }

  assert {
    condition = (
      aws_ssm_parameter.platform["sa-east-1/site-zones"].insecure_value == "cliente.com.br" &&
      aws_ssm_parameter.platform["sa-east-1/zone-owners"].insecure_value == "cliente.com.br=web-cliente,joshuel.com.br=web-joshuel"
    )
    error_message = "Customer zones (site-zones) and the owner of every zone (zone-owners) are published with the rest; the platform's zone is not a customer zone."
  }
}
