variable "region" {
  type        = string
  description = "AWS region where the VPC is created"
}

variable "project_name" {
  type        = string
  description = "Project name. Prefix for resources and SSM parameters (e.g. jonomait-multiregion)"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Public subnets (one per AZ)"
}

variable "private_subnets" {
  type = list(object({
    name              = string
    cidr              = string
    availability_zone = string
  }))
  description = "Private subnets (each AZ needs a public subnet)"
}
