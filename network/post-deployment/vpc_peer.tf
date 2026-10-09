resource "aws_vpc_peering_connection" "peer" {
  vpc_id      = data.aws_ssm_parameter.vpc.value
  peer_vpc_id = data.aws_ssm_parameter.vpc_peer.value

  peer_owner_id = data.aws_caller_identity.peer.account_id
  peer_region   = var.region_peer

  auto_accept = false

  tags = {
    Side = "Requester"
  }
}

resource "aws_vpc_peering_connection_accepter" "peer" {
  provider                  = aws.peer
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}

resource "aws_vpc_peering_connection_options" "requester" {
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [
    aws_vpc_peering_connection.peer,
    aws_vpc_peering_connection_accepter.peer
  ]
}


resource "aws_vpc_peering_connection_options" "accepter" {

  provider = aws.peer

  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [
    aws_vpc_peering_connection.peer,
    aws_vpc_peering_connection_accepter.peer
  ]
}
# Peering não cria rota sozinho: cada lado precisa saber que o CIDR do outro sai pelo pcx.
# Usa o id do accepter para a rota só ser criada depois que o peering estiver ativo.
resource "aws_route" "to_peer" {
  for_each = toset(data.aws_route_tables.vpc.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.peer.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}

resource "aws_route" "from_peer" {
  provider = aws.peer
  for_each = toset(data.aws_route_tables.peer.ids)

  route_table_id            = each.value
  destination_cidr_block    = data.aws_vpc.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer.id
}
