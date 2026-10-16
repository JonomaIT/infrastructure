output "ingress" {
  description = "Entry of the environment; apps point their names here (ADR-010)"
  value       = local.ingress
}

output "mode" {
  description = "cname (one region) or load-balancer (two regions, failover in order)"
  value       = local.multi ? "load-balancer: ${join(" → ", var.regions)}" : "cname: ${var.regions[0]}"
}
