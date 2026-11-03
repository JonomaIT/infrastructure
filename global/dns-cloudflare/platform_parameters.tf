# The platform parameter that follows the entry: which regions process now (ADR-013). It changes
# with mode and out, in the same apply as the load balancer and region-state.
#
#   /jonomait/<env>/platform/active-regions  a worker takes the copies of a region missing here
#
# The rest of the platform's parameters (zone, regions, allow-destroy, site-zones) live in
# global/platform, which does not depend on the lab and is never destroyed with it.
locals {
  platform_parameters = {
    active-regions = { value = join(",", local.active_regions), description = "Regions processing now (${var.mode}): a worker takes the copies of a region missing here (ADR-013)" }
  }
}

resource "aws_ssm_parameter" "platform" {
  for_each = { for pair in setproduct(keys(local.platform_parameters), var.regions) : "${pair[1]}/${pair[0]}" => { key = pair[0], region = pair[1] } }

  region         = each.value.region
  name           = "/jonomait/${var.environment}/platform/${each.value.key}"
  description    = local.platform_parameters[each.value.key].description
  type           = "String"
  insecure_value = local.platform_parameters[each.value.key].value # not secrets: readable in plans
}
