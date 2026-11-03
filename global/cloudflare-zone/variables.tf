# Only a guard: the validation stops this component from running in any other account.
# tflint-ignore: terraform_unused_declarations
variable "environment" {
  type        = string
  description = "Account holding this state: the zone is shared, so it runs only from shared-services"

  validation {
    condition     = var.environment == "shared-services"
    error_message = "cloudflare-zone runs only from shared-services."
  }
}

variable "zones" {
  type        = list(string)
  description = "Cloudflare zones whose settings Terraform owns: the platform's and the customer zones of global/platform (site_zones)"

  validation {
    condition     = length(var.zones) >= 1
    error_message = "zones must list at least the platform's zone."
  }
}
