output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = module.cluster.cluster_name
}

output "lb_external_dns" {
  description = "DNS do load balancer externo"
  value       = module.cluster.lb_external_dns
}

output "ssm_parameters" {
  description = "Parâmetros SSM publicados por esta stack"
  value = [
    aws_ssm_parameter.cluster_name.name,
    aws_ssm_parameter.lb_external_arn.name,
    aws_ssm_parameter.lb_external_listener_arn.name,
    aws_ssm_parameter.lb_internal_arn.name,
    aws_ssm_parameter.lb_internal_listener_arn.name,
    aws_ssm_parameter.service_discovery_namespace_name.name,
    aws_ssm_parameter.service_discovery_namespace_id.name,
    aws_ssm_parameter.service_connect_namespace_name.name,
    aws_ssm_parameter.service_connect_namespace_id.name,
    aws_ssm_parameter.vpc_link_id.name,
    aws_ssm_parameter.vpc_link_nlb_arn.name,
  ]
}
