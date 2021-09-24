variable "cidr_block" {
  type = string
}

variable "name" {
  type = string
}

#variable "vpc_tags" {
#  description = "Tags to apply to the VPC"
#  type        = list
#}

variable "az_map" {
  type = map
  default = {
    0 = "us-east-1c",
    1 = "us-east-1d",
    2 = "us-east-1e",
    3 = "us-east-1a",
    4 = "us-east-1f",
    5 = "us-east-1b"
  }
}

variable "az_count" {
  type    = number
  default = 3
}

variable "eks_cluster_name" {
  type = string
}

variable "eip" {
  type    = string
  default = ""
}

variable "environment" {
  type    = string
  default = ""
}

variable "project" {
  type    = string
  default = "hdasp"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

