variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list
}

variable "s3_bucket" {
  type = string
}

variable "ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-2016-08"
}

variable "certificate_arn" {
  type = string
}

variable "instance_ids" {
  type = list
}

variable "ip_address_type" {
  type    = string
  default = "ipv4"
}

variable "alb_tg_instance_listener_port" {
  type    = string
  default = 80
}

variable "alb_target_group_port" {
  type    = string
  default = 80
}