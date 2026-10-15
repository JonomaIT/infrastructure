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
