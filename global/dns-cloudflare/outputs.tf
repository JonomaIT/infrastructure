output "ingress" {
  description = "Entry of the environment; apps point their names here (ADR-010)"
  value       = local.ingress
}

output "region_state" {
  description = "ACTIVE or PASSIVE per region (ADR-012)"
  value       = { for r, p in aws_ssm_parameter.region_state : r => p.insecure_value }
}

output "mode" {
  description = "cname (one region) or load-balancer (two regions: failover in order, or active-active)"
  value       = local.multi ? "load-balancer, ${var.mode}: ${join(var.mode == "active-active" ? " + " : " → ", local.serving)}" : "cname: ${var.regions[0]}"
}

output "platform_parameters" {
  description = "What the platform decides for every app (ADR-014): zone, regions and whether app data may be destroyed"
  value       = { for k, p in local.platform_parameters : k => p.value }
}
