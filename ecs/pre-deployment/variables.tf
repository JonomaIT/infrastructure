variable "project_name" {
  type        = string
  description = "Cluster project name, used as the SSM prefix (e.g. jonomait-ecs)"
}

variable "region" {
  type        = string
  description = "Primary AWS region"
}

variable "region_secondary" {
  type        = string
  description = "Secondary AWS region (gets its own copy of the certificate: ACM is regional)"
}

variable "cloudflare_zone" {
  type        = string
  description = "Cloudflare zone holding the validation records (e.g. joshuel.com.br); the zone id is looked up from it"
}

variable "acm_dns_certs" {
  type        = list(string)
  description = "Names covered by the certificate. The first is the main name, the rest become SANs (e.g. [\"*.joshuel.com.br\"])"

  validation {
    condition     = length(var.acm_dns_certs) > 0
    error_message = "acm_dns_certs needs at least one name."
  }
}
