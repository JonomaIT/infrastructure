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
  description = "Account whose platform parameters these are"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be staging or production."
  }
}

variable "zone" {
  type        = string
  description = "Cloudflare zone of the apps' public names (e.g. joshuel.com.br)"
}

variable "regions" {
  type        = list(string)
  description = "Regions the platform runs, primary first (the same as in dns-cloudflare)"

  validation {
    condition     = length(var.regions) >= 1 && length(var.regions) <= 2
    error_message = "regions must list 1 or 2 regions, primary first."
  }
}

variable "site_zones" {
  type        = list(string)
  description = "Other Cloudflare zones a site may have names in (a customer's own domain). Each must exist in Cloudflare, with global/cloudflare-zone managing its settings"
  default     = []
}

variable "allow_destroy_app_data" {
  type        = bool
  description = "Labs only: app data (tables, buckets) loses deletion protection so a teardown can remove it. A real production keeps false"
  default     = false
}
