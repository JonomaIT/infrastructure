variable "project_name" {
  type        = string
  description = "Cluster project name. Prefix for resources and SSM parameters (e.g. jonomait-ecs)"
}

variable "region" {
  type        = string
  description = "AWS region where the cluster is created"
}

variable "ssm_vpc_id" {
  type        = string
  description = "SSM parameter with the VPC ID, published by the network stack"
}

variable "ssm_private_subnets" {
  type        = list(string)
  description = "SSM parameters with the private subnet IDs, published by the network stack"
}

variable "ssm_public_subnets" {
  type        = list(string)
  description = "SSM parameters with the public subnet IDs, published by the network stack"
}

variable "ssm_acm_certs" {
  type        = list(string)
  description = "SSM parameters with ACM certificate ARNs, published by ecs/pre-deployment. Empty = HTTP only"
  default     = []
}
