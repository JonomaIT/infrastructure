output "cluster_name" {
  description = "ECS cluster (apps find it by the name jonomait-<env>-ecs)"
  value       = module.ecs_cluster.cluster_name
}

output "namespace_name" {
  description = "Service-to-service namespace"
  value       = module.ecs_cluster.namespace_name
}
