project_name = "jonomait-ecs"
region       = "sa-east-1"

ssm_vpc_id = "/jonomait-multiregion/vpc/vpc_id"

ssm_private_subnets = [
  "/jonomait-multiregion/vpc/private/sa-east-1a",
  "/jonomait-multiregion/vpc/private/sa-east-1b",
  "/jonomait-multiregion/vpc/private/sa-east-1c"
]
ssm_public_subnets = [
  "/jonomait-multiregion/vpc/public/sa-east-1a",
  "/jonomait-multiregion/vpc/public/sa-east-1b",
  "/jonomait-multiregion/vpc/public/sa-east-1c"
]