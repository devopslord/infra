variable "name" {
  type = string
}

variable "split_tunnel" {
  type    = bool
  default = false
}

variable "server_cert_arn" {
  type = string
}

variable "client_cert_arn" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "log_group" {
  type    = string
  default = "/aws/vpn/"
}

variable "vpc_id" {
  type = string
}
