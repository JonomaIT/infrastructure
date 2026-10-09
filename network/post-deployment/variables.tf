variable "region" {
  type        = string
  description = "Região da VPC que solicita o peering (requester)"
}

variable "region_peer" {
  type        = string
  description = "Região da VPC que aceita o peering (accepter)"
}

variable "vpc_ssm" {
  type        = string
  description = "Parâmetro SSM com o ID da VPC requester"
}

variable "vpc_ssm_peer" {
  type        = string
  description = "Parâmetro SSM com o ID da VPC accepter"
}
