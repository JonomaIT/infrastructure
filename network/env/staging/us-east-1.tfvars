environment = "staging"
region      = "us-east-1"
cidr        = "10.10.0.0/16"
azs         = ["us-east-1a", "us-east-1b"]

single_nat_gateway = true # lab cost: one NAT for the VPC
