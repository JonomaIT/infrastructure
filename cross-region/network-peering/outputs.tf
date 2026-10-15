output "peering_id" {
  description = "VPC peering connection"
  value       = aws_vpc_peering_connection_accepter.main.id
}

output "ranges" {
  description = "Ranges connected by the peering"
  value       = { (var.regions[0]) = data.aws_vpc.primary.cidr_block, (var.regions[1]) = data.aws_vpc.secondary.cidr_block }
}
