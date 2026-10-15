variable "environment" {
  type        = string
  description = "Account this component runs in"

  validation {
    condition     = contains(["shared-services", "staging", "production"], var.environment)
    error_message = "environment must be shared-services, staging or production."
  }
}

variable "region" {
  type        = string
  description = "AWS region of this VPC"
}

variable "cidr" {
  type        = string
  description = "VPC range, from the CIDR plan (Organização de Contas AWS, section 6): a /16 inside 10.0.0.0/8"

  validation {
    condition     = can(cidrnetmask(var.cidr)) && endswith(var.cidr, "/16") && startswith(var.cidr, "10.")
    error_message = "cidr must be a /16 inside 10.0.0.0/8 (172.16/12 and 192.168/16 are kept free for Cloudflare WARP)."
  }
}

variable "azs" {
  type        = list(string)
  description = "Availability zones (2 or 3); the ALB needs at least 2"

  validation {
    condition     = length(var.azs) >= 2 && length(var.azs) <= 3
    error_message = "Use 2 or 3 availability zones."
  }
}

variable "single_nat_gateway" {
  type        = bool
  description = "One NAT Gateway instead of one per AZ (cheaper; acceptable outside production)"
  default     = false
}
