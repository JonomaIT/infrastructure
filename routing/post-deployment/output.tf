output "global_accelerator_dns" {
  description = "Global Accelerator DNS name"
  value       = aws_globalaccelerator_accelerator.main.dns_name
}

output "global_accelerator_ips" {
  description = "Global Accelerator static anycast IPs"
  value       = flatten(aws_globalaccelerator_accelerator.main.ip_sets[*].ip_addresses)
}

output "dns_name" {
  description = "Public name pointing to the accelerator"
  value       = cloudflare_record.main.hostname
}
