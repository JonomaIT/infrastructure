data "aws_ssm_parameter" "vpc" {
  name = var.vpc_ssm
}

data "aws_ssm_parameter" "vpc_peer" {
  provider = aws.peer
  name     = var.vpc_ssm_peer
}

data "aws_caller_identity" "current" {}

data "aws_caller_identity" "peer" {
  provider = aws.peer
}
data "aws_vpc" "vpc" {
  id = data.aws_ssm_parameter.vpc.value
}

data "aws_vpc" "peer" {
  provider = aws.peer
  id       = data.aws_ssm_parameter.vpc_peer.value
}

data "aws_route_tables" "vpc" {
  vpc_id = data.aws_ssm_parameter.vpc.value
}

data "aws_route_tables" "peer" {
  provider = aws.peer
  vpc_id   = data.aws_ssm_parameter.vpc_peer.value
}
