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
  description = "AWS region of this ALB"
}

variable "zone" {
  type        = string
  description = "Cloudflare zone; the certificate covers *.<zone> (production app.<zone> and staging app-stg.<zone>)"
}

variable "create_validation_records" {
  type        = bool
  description = "Create the ACM validation record in Cloudflare: true in the account's primary region only (the record is the same in every region)"
}

variable "deletion_protection" {
  type        = bool
  description = "Refuse to delete the ALB (true in production)"
  default     = false
}
