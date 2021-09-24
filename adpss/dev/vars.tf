variable "name" {
  type    = string
  default = "adpss-dev"
}

variable "nametest" {
  type    = string
  default = "adpss-dev-test"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "adpss"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "log_format" {
  type    = string
  default = "$${version} $${vpc-id} $${subnet-id} $${instance-id} $${interface-id} $${account-id} $${type} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${pkt-srcaddr} $${pkt-dstaddr} $${protocol} $${bytes} $${packets} $${start} $${end} $${action} $${tcp-flags} $${log-status}"
}

variable "adpss_dev_sg_id" {
  default = "sg-03a3b87dff4442334"
}

variable "ami" {
  type    = string
  default = "ami-00f7dbe1ae53c10f8"
}
