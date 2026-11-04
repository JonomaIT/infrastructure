variable "prefix" {
  type        = string
  description = "Platform prefix (PROJECT_PREFIX org variable; the pipeline passes TF_VAR_prefix): names <prefix>-<env>-..., parameters /<prefix>/<env>/..., tags <prefix>:*"

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{1,14}$", var.prefix))
    error_message = "prefix must be 2-15 lowercase letters and digits."
  }
}

variable "environment" {
  type        = string
  description = "Account whose two VPCs are peered"

  validation {
    condition     = contains(["shared-services", "staging", "production"], var.environment)
    error_message = "environment must be shared-services, staging or production."
  }
}

variable "regions" {
  type        = list(string)
  description = "Primary and secondary regions, in this order"

  validation {
    condition     = length(var.regions) == 2 && var.regions[0] != var.regions[1]
    error_message = "regions must be exactly two different regions: primary, secondary."
  }
}
