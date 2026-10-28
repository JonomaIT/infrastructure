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

variable "mode" {
  type        = string
  description = "active-passive: traffic and processing in the first region, the others take over on failover (ADR-012). active-active: every region takes traffic and processes what is created in it (ADR-013)"
  default     = "active-passive"

  validation {
    condition     = contains(["active-passive", "active-active"], var.mode)
    error_message = "mode must be active-passive or active-active."
  }
}

variable "out" {
  type        = list(string)
  description = "active-active only: regions taken out (failover). They get no traffic and turn PASSIVE; the other regions process their copies (standby queues). Back in = remove from the list"
  default     = []

  validation {
    condition     = alltrue([for r in var.out : contains(var.regions, r)]) && length(var.out) < length(var.regions)
    error_message = "out lists regions of regions, and at least one region must stay in."
  }

  validation {
    condition     = length(var.out) == 0 || var.mode == "active-active"
    error_message = "out is for active-active; in active-passive a failover puts another region first in regions."
  }
}

variable "allow_destroy_app_data" {
  type        = bool
  description = "Labs only: app data (tables, buckets) loses deletion protection so a teardown can remove it. A real production keeps false"
  default     = false
}
