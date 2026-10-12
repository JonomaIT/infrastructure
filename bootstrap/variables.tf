variable "region" {
  type        = string
  description = "Provider region (IAM is global; the region only affects API calls)"
}

variable "github_org" {
  type        = string
  description = "GitHub organization that owns the repository (e.g. JonomaIT)"
}

variable "github_repo" {
  type        = string
  description = "Repository allowed to assume the role (e.g. infrastructure)"
}

variable "github_org_id" {
  type        = string
  description = "Numeric organization ID (gh api orgs/<org> -q .id), used in the immutable OIDC sub"
}

variable "github_repo_id" {
  type        = string
  description = "Numeric repository ID (gh api repos/<org>/<repo> -q .id), used in the immutable OIDC sub"
}

variable "state_bucket" {
  type        = string
  description = "S3 bucket holding the Terraform states"
}

variable "ssm_prefixes" {
  type        = list(string)
  description = "SSM parameter prefixes the pipeline may manage, one per stack (e.g. /jonomait-multiregion)"
}
