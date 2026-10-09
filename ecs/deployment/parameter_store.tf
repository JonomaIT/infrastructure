# Publica no SSM o que os serviços vão precisar do cluster, por convenção de nome:
# /<project_name>/<recurso>/... Assim ninguém lê o state desta stack.
resource "aws_ssm_parameter" "cluster_name" {
  type  = "String"
  name  = format("/%s/cluster/name", var.project_name)
  value = module.cluster.cluster_name
}

resource "aws_ssm_parameter" "lb_external_arn" {
  type  = "String"
  name  = format("/%s/lb/external/arn", var.project_name)
  value = module.cluster.lb_external_arn
}

resource "aws_ssm_parameter" "lb_external_listener_arn" {
  type  = "String"
  name  = format("/%s/lb/external/listener", var.project_name)
  value = module.cluster.lb_external_listener_arn
}

resource "aws_ssm_parameter" "lb_internal_arn" {
  type  = "String"
  name  = format("/%s/lb/internal/arn", var.project_name)
  value = module.cluster.lb_internal_arn
}

resource "aws_ssm_parameter" "lb_internal_listener_arn" {
  type  = "String"
  name  = format("/%s/lb/internal/listener", var.project_name)
  value = module.cluster.lb_internal_listener_arn
}

resource "aws_ssm_parameter" "service_discovery_namespace_name" {
  type  = "String"
  name  = format("/%s/service-discovery/cloudmap/name", var.project_name)
  value = module.cluster.service_discovery_namespace_name
}

resource "aws_ssm_parameter" "service_discovery_namespace_id" {
  type  = "String"
  name  = format("/%s/service-discovery/cloudmap/id", var.project_name)
  value = module.cluster.service_discovery_namespace_id
}

resource "aws_ssm_parameter" "service_connect_namespace_name" {
  type  = "String"
  name  = format("/%s/service-discovery/service-connect/name", var.project_name)
  value = module.cluster.service_connect_namespace_name
}

resource "aws_ssm_parameter" "service_connect_namespace_id" {
  type  = "String"
  name  = format("/%s/service-discovery/service-connect/id", var.project_name)
  value = module.cluster.service_connect_namespace_id
}

resource "aws_ssm_parameter" "vpc_link_id" {
  type  = "String"
  name  = format("/%s/vpc-link/id", var.project_name)
  value = module.cluster.vpc_link_id
}

resource "aws_ssm_parameter" "vpc_link_nlb_arn" {
  type  = "String"
  name  = format("/%s/vpc-link/nlb-arn", var.project_name)
  value = module.cluster.vpc_link_nlb_arn
}
