variable "region" {
  type        = string
  description = "Region of the VPC requesting the peering (requester)"
}

variable "region_peer" {
  type        = string
  description = "Region of the VPC accepting the peering (accepter)"
}

variable "vpc_ssm" {
  type        = string
  description = "SSM parameter with the requester VPC ID"
}

variable "vpc_ssm_peer" {
  type        = string
  description = "SSM parameter with the accepter VPC ID"
}
