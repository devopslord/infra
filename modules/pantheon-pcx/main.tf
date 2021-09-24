resource "aws_vpc_peering_connection" "main" {
  vpc_id      = var.vpc_id
  peer_vpc_id = var.peer_vpc_id
  auto_accept = true
}

resource "aws_route" "main" {
  count = length(var.route_table_ids)

  route_table_id            = var.route_table_ids[count.index]
  destination_cidr_block    = var.peer_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

resource "aws_route" "peer" {
  count = length(var.peer_route_table_ids)

  route_table_id            = var.peer_route_table_ids[count.index]
  destination_cidr_block    = var.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}
