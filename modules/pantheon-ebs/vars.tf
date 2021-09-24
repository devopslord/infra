variable "availability_zone" {
  type = string
}

variable "size" {
  type = string
}

variable "encrypted" {
  type    = bool
  default = true
}

variable "type" {
  type    = string
  default = "gp2"
}

variable "name" {
  type = string
}

variable "device_name" {
  type    = string
  default = "/dev/sdh"
}

variable "instance_id" {
  type = string
}

variable "environment" {
  type    = string
  default = ""
}

variable "project" {
  type    = string
  default = ""
}

variable "region" {
  type    = string
  default = ""
}