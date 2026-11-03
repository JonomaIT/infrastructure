terraform {
  # Bucket from backends/<account>.tfbackend; key passed at init (see README).
  backend "s3" {
    use_lockfile = true
  }
}
