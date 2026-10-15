environment = "production"
region      = "sa-east-1"
cidr        = "10.120.0.0/16"
azs         = ["sa-east-1a", "sa-east-1b"]

single_nat_gateway = true # lab cost; a real production uses one NAT per AZ (false)
