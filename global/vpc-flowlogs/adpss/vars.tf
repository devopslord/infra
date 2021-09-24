variable "vpc_id" {
  type = string
  default = "vpc-0af672464104de6ff"
}

variable "cw_log_destination_arn" {
  type = string
  default = "arn:aws:logs:us-east-1:631203585119:log-group:/adpss/vpc"
}

variable "log_format" {
  type = string
  default = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${az-id} $${log-status}"
}