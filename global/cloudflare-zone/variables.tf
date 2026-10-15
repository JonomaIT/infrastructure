variable "environment" {
  type        = string
  description = "Account holding this state: the zone is shared, so it runs only from shared-services"

  validation {
    condition     = var.environment == "shared-services"
    error_message = "cloudflare-zone runs only from shared-services."
  }
}

variable "zone" {
  type        = string
  description = "Cloudflare zone (e.g. joshuel.com.br)"
}
