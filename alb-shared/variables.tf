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

variable "create_validation_records" {
  type        = bool
  description = "Create the ACM validation record in Cloudflare: true in the account's primary region only (the record is the same in every region)"
}

variable "deletion_protection" {
  type        = bool
  description = "Refuse to delete the ALB (true in production)"
  default     = false
}
