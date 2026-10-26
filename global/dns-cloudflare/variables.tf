variable "environment" {
  type        = string
  description = "Account whose ALBs the entry points to"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "environment must be staging or production."
  }
}

variable "zone" {
  type        = string
  description = "Cloudflare zone (e.g. joshuel.com.br)"
}

variable "regions" {
  type        = list(string)
  description = "Regions with a shared ALB, primary first. Two regions turn on Cloudflare Load Balancing with failover in this order"

  validation {
    condition     = length(var.regions) >= 1 && length(var.regions) <= 2
    error_message = "regions must list 1 or 2 regions, primary first."
  }
}

variable "allow_destroy_app_data" {
  type        = bool
  description = "Labs only: app data (tables, buckets) loses deletion protection so a teardown can remove it. A real production keeps false"
  default     = false
}
