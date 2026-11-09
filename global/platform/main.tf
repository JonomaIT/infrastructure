# What the platform decides for every app of the environment, published where the runners read it
# (ADR-014). These are never variables an app could set from its own files: the runners read them
# here, so an app's deploy/ cannot change the zone, the regions or the data protections.
#
# Persistent: it does not depend on the lab (no ALB, no cluster), so a destroy of everything leaves
# it (terraform-deploy persistent). A permanent workload, such as a customer's site, keeps
# deploying while the lab is down.
#
#   /<prefix>/<env>/platform/zone            the Cloudflare zone of the public names (also read by
#                                            alb-shared and dns-cloudflare: one place per environment)
#   /<prefix>/<env>/platform/regions         the regions the platform runs (apps pick among them)
#   /<prefix>/<env>/platform/allow-destroy   "true" only in a lab: app data may be destroyed
#   /<prefix>/<env>/platform/zone-owners     zone=app,…: the platform zone's apex and each customer
#                                            zone belong to one app only (only when there is one)
#   /<prefix>/<env>/platform/site-zones      other zones a site may have names in (a customer's
#                                            own domain); only when there is one
#
# The parameters that follow the entry (region-state, active-regions) stay in dns-cloudflare.

locals {
  # Customer zones: every owned zone that is not the platform's.
  site_zones = sort([for z in keys(var.zone_owners) : z if z != var.zone])

  parameters = merge(
    {
      zone            = { value = var.zone, description = "Cloudflare zone of the apps' public names (ADR-010)" }
      regions         = { value = join(",", var.regions), description = "Regions the platform runs, primary first: apps may only use these" }
      "allow-destroy" = { value = tostring(var.allow_destroy_app_data), description = "true only in a lab: app data loses deletion protection so a teardown can remove it" }
    },
    length(local.site_zones) == 0 ? {} : {
      site-zones = { value = join(",", local.site_zones), description = "Other zones a site may have names in, e.g. a customer's own domain (the site gets its own certificate)" }
    },
    length(var.zone_owners) == 0 ? {} : {
      zone-owners = { value = join(",", [for z in sort(keys(var.zone_owners)) : "${z}=${var.zone_owners[z]}"]), description = "zone=app: the platform zone's apex and each customer zone belong to that app only" }
    },
  )
}

resource "aws_ssm_parameter" "platform" {
  for_each = { for pair in setproduct(keys(local.parameters), var.regions) : "${pair[1]}/${pair[0]}" => { key = pair[0], region = pair[1] } }

  region         = each.value.region
  name           = "/${var.prefix}/${var.environment}/platform/${each.value.key}"
  description    = local.parameters[each.value.key].description
  type           = "String"
  insecure_value = local.parameters[each.value.key].value # not secrets: readable in plans
}
