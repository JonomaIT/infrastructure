# Region state (ADR-012): the first region of var.regions is ACTIVE, every other one PASSIVE.
# Apps read /jonomait/<env>/platform/region-state in their own region (the ECS runner passes the
# name as REGION_STATE_PARAMETER): e.g. a worker only processes while its region is ACTIVE.
#
# It lives next to the failover order of the entry on purpose: changing the order of var.regions
# moves the traffic (load balancer pools) and the processing (this parameter) in the same apply.
resource "aws_ssm_parameter" "region_state" {
  for_each = toset(var.regions)

  region      = each.value
  name        = "/jonomait/${var.environment}/platform/region-state"
  description = "ACTIVE or PASSIVE: the first region of the entry's failover order is ACTIVE (ADR-012)"
  type        = "String"
  # Not a secret: insecure_value keeps it readable in plans (value is always masked).
  insecure_value = each.value == var.regions[0] ? "ACTIVE" : "PASSIVE"
}
