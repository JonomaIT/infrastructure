output "parameters" {
  description = "What the platform decides for every app (ADR-014): zone, regions, data protection and the zones sites may use"
  value       = { for k, p in local.parameters : k => p.value }
}
