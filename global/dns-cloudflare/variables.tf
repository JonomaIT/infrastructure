variable "environment" {
  type        = string
  description = "Account whose ALBs the names point to"

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

variable "records" {
  type = map(object({
    health_check_path = optional(string, "/health")
  }))
  description = "Public names (without the zone) => options. Staging names end in -stg (e.g. hello-stg), production names do not"

  validation {
    condition     = alltrue([for name in keys(var.records) : can(regex("^[a-z0-9-]+$", name))])
    error_message = "Record names are a single label of lowercase letters, digits and hyphens (no dots: Universal SSL covers one level)."
  }
}
