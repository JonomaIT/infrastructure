output "registry" {
  description = "Registry of the app images (the region in it is swapped for each deploy region)"
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "repositories" {
  description = "App repositories"
  value       = [for r in aws_ecr_repository.app : r.name]
}
