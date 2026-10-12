variable "project_name" {
  type        = string
  description = "Project name (e.g. jonomait-routing)"
}

variable "region" {
  type        = string
  description = "AWS region of the provider"
}

variable "cloudflare_zone" {
  type        = string
  description = "Cloudflare zone whose security settings this component owns (e.g. joshuel.com.br)"
}
