variable "cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/f02225c0-4e12-4ecc-a7f9-a9320da1c626"
}

variable "tennable_scanner_sg" {
  type    = string
  default = "sg-045253f618c437bef"
}

variable "project" {
  type    = string
  default = "adass"
}

variable "region" {
  type    = string
  default = "us-east-1"
}
variable "environment" {
  type    = string
  default = "production"
}