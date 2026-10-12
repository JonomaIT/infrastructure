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

variable "cloudflare_zone" {
  type        = string
  description = "Cloudflare zone for the public name (e.g. joshuel.com.br); the zone id is looked up from it"
}

variable "dns_name" {
  type        = string
  description = "Public name pointing to the accelerator, inside cloudflare_zone (e.g. multiregion.joshuel.com.br)"
}

variable "cloudflare_proxied" {
  type        = bool
  description = "Put Cloudflare's proxy in front of the accelerator (false = DNS only)"
  default     = false
}
