output "ingress" {
  description = "Entry of the environment; apps point their names here (ADR-010)"
  value       = local.ingress
}

output "region_state" {
  description = "ACTIVE or PASSIVE per region (ADR-012)"
  value       = { for r, p in aws_ssm_parameter.region_state : r => p.insecure_value }
}

output "mode" {
  description = "cname (one region) or load-balancer (two regions, failover in order)"
  value       = local.multi ? "load-balancer: ${join(" → ", var.regions)}" : "cname: ${var.regions[0]}"
}
