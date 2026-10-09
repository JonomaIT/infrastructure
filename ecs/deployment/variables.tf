variable "project_name" {
  type        = string
  description = "Nome do projeto do cluster. Prefixo dos recursos e dos parâmetros SSM (ex: jonomait-ecs)"
}

variable "region" {
  type        = string
  description = "Região AWS onde o cluster é criado"
}

variable "ssm_vpc_id" {
  type        = string
  description = "Parâmetro SSM com o ID da VPC, publicado pela stack network"
}

variable "ssm_private_subnets" {
  type        = list(string)
  description = "Parâmetros SSM com os IDs das subnets privadas, publicados pela stack network"
}

variable "ssm_public_subnets" {
  type        = list(string)
  description = "Parâmetros SSM com os IDs das subnets públicas, publicados pela stack network"
}
