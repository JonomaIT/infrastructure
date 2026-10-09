project_name = "jonomait-ecs"
region       = "us-east-1"

ssm_vpc_id = "/jonomait-multiregion/vpc/vpc_id"

ssm_private_subnets = [
  "/jonomait-multiregion/vpc/private/us-east-1a",
  "/jonomait-multiregion/vpc/private/us-east-1b",
  "/jonomait-multiregion/vpc/private/us-east-1c"
]
ssm_public_subnets = [
  "/jonomait-multiregion/vpc/public/us-east-1a",
  "/jonomait-multiregion/vpc/public/us-east-1b",
  "/jonomait-multiregion/vpc/public/us-east-1c"
]