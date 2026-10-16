variable "environment" {
  type        = string
  description = "Account holding the registry: images are built once and promoted, so only shared-services"

  validation {
    condition     = var.environment == "shared-services"
    error_message = "ecr runs only in shared-services."
  }
}

variable "region" {
  type        = string
  description = "Region of the registry (the primary)"
}

variable "repositories" {
  type        = list(string)
  description = "One repository per app that ships an image (name = repo name)"
}

variable "replica_regions" {
  type        = list(string)
  description = "Regions that get a copy of every image (each region pulls from its own copy)"
  default     = []
}

variable "keep_images" {
  type        = number
  description = "Images kept per repository (older ones expire)"
  default     = 30
}

variable "force_delete" {
  type        = bool
  description = "Allow destroying repositories that still have images (labs)"
  default     = false
}
