variable "region" {
  type        = string
  description = "Região AWS onde a VPC é criada"
}

variable "project_name" {
  type        = string
  description = "Nome do projeto. Prefixo dos recursos e dos parâmetros SSM (ex: jonomait-multiregion)"
}

variable "cidr" {
  type        = string
  description = "Bloco CIDR da VPC"
}

variable "public_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Subnets públicas (uma por AZ)"
}

variable "private_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Subnets privadas (cada AZ precisa de uma subnet pública)"
}
