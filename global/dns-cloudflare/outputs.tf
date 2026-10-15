output "names" {
  description = "Public names managed here"
  value       = values(local.fqdn)
}

output "mode" {
  description = "cname (one region) or load-balancer (two regions, failover in order)"
  value       = local.multi ? "load-balancer: ${join(" → ", var.regions)}" : "cname: ${var.regions[0]}"
}
