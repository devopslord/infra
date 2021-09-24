variable "vpc_id" {
  type = string
}

variable "peer_vpc_id" {
  type = string
}

variable "route_table_ids" {
  type = list
}

variable "peer_route_table_ids" {
  type = list
}

variable "cidr_block" {
  type = string
}

variable "peer_cidr_block" {
  type = string
}
