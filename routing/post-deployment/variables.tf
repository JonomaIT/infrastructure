variable "project_name" {
  type        = string
  description = "Project name, used as the accelerator name (e.g. jonomait-routing)"
}

variable "region_primary" {
  type        = string
  description = "Primary region (also the region of the default provider)"
}

variable "region_secondary" {
  type        = string
  description = "Secondary region"
}

variable "nlb_arn_primary_ssm" {
  type        = string
  description = "SSM parameter with the ARN of the primary region NLB, published by the ecs stack"
}

variable "nlb_arn_secondary_ssm" {
  type        = string
  description = "SSM parameter with the ARN of the secondary region NLB, published by the ecs stack"
}

variable "routing" {
  type = object({
    primary   = number
    secondary = number
  })
  description = "Traffic dial (0-100) per region. 100/0 = active-passive; 50/50 = active-active"

  validation {
    condition = alltrue([
      for v in [var.routing.primary, var.routing.secondary] : v >= 0 && v <= 100
    ])
    error_message = "Each traffic dial must be between 0 and 100."
  }
}

variable "route53_hosted_zone" {
  type        = string
  description = "Route 53 public hosted zone ID for the optional DNS name (null = no record)"
  default     = null
}

variable "dns_name" {
  type        = string
  description = "Optional public DNS name for the accelerator, inside route53_hosted_zone (null = no record)"
  default     = null
}
