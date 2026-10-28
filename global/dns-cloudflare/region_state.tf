# Region state, next to the entry on purpose: one apply moves the traffic (load balancer pools) and
# the processing (these parameters) together.
#
#   active-passive (ADR-012)  the first region of var.regions is ACTIVE, every other one PASSIVE;
#                             a failover puts another region first
#   active-active  (ADR-013)  every region is ACTIVE, except those in var.out (failover)
#
# Apps read /jonomait/<env>/platform/region-state in their own region (the ECS runner passes the
# name as REGION_STATE_PARAMETER): e.g. a worker only processes while its region is ACTIVE.
# active-regions (platform_parameters.tf) tells a worker whether another region is out, so it also
# takes that region's copies (standby queues).
locals {
  active_regions = var.mode == "active-active" ? [for r in var.regions : r if !contains(var.out, r)] : [var.regions[0]]
}

resource "aws_ssm_parameter" "region_state" {
  for_each = toset(var.regions)

  region      = each.value
  name        = "/jonomait/${var.environment}/platform/region-state"
  description = "ACTIVE or PASSIVE: whether this region processes (ADR-012, ADR-013)"
  type        = "String"
  # Not a secret: insecure_value keeps it readable in plans (value is always masked).
  insecure_value = contains(local.active_regions, each.value) ? "ACTIVE" : "PASSIVE"
}
