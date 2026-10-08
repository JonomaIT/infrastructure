terraform {
  backend "s3" {
    use_lockfile = true # lock nativo no S3 (Terraform >= 1.10)
  }
}
