output "vpc_id" {
  description = "VPC ID (other components find it by the Name tag jonomait-<env>-network)"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC range"
  value       = module.vpc.vpc_cidr
}

output "nat_gateway_count" {
  description = "NAT Gateways (each one bills hourly)"
  value       = module.vpc.nat_gateway_count
}
