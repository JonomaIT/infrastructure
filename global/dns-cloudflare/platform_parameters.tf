# What the platform decides for every app of the environment, published where the runners read it
# (ADR-014). These are never variables an app could set from its own files: the runners read them
# here, so an app's deploy/ cannot change the zone, the regions or the data protections.
#
#   /jonomait/<env>/platform/zone            the Cloudflare zone of the public names
#   /jonomait/<env>/platform/regions         the regions the platform runs (apps pick among them)
#   /jonomait/<env>/platform/allow-destroy   "true" only in a lab: app data may be destroyed
#   /jonomait/<env>/platform/active-regions  the regions processing now (region_state.tf)
locals {
  platform_parameters = {
    zone            = { value = var.zone, description = "Cloudflare zone of the apps' public names (ADR-010)" }
    regions         = { value = join(",", var.regions), description = "Regions the platform runs, primary first: apps may only use these" }
    "allow-destroy" = { value = tostring(var.allow_destroy_app_data), description = "true only in a lab: app data loses deletion protection so a teardown can remove it" }
    active-regions  = { value = join(",", local.active_regions), description = "Regions processing now (${var.mode}): a worker takes the copies of a region missing here (ADR-013)" }
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
