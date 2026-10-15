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
  description = "AWS region of this cluster"
}

variable "container_insights" {
  type        = string
  description = "enabled, enhanced or disabled (enabled/enhanced bill CloudWatch metrics)"
  default     = "enabled"
}
