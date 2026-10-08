variable "region" {
  type        = string
  description = "Região do provider (IAM é global; a região só afeta as chamadas de API)"
}

variable "github_org" {
  type        = string
  description = "Organização do GitHub dona do repositório (ex: JonomaIT)"
}

variable "github_repo" {
  type        = string
  description = "Repositório que pode assumir a role (ex: infrastructure)"
}

variable "state_bucket" {
  type        = string
  description = "Bucket S3 onde ficam os states do Terraform"
}

variable "ssm_prefix" {
  type        = string
  description = "Prefixo dos parâmetros SSM que a pipeline pode gerenciar (ex: /jonomait-multiregion)"
}
