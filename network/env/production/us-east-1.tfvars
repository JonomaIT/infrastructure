# pipeline test (this PR is closed without merging)
environment = "production"
region      = "us-east-1"
cidr        = "10.20.0.0/16"
azs         = ["us-east-1a", "us-east-1b"]

single_nat_gateway = true # lab cost; a real production uses one NAT per AZ (false)
