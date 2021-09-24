variable "name" {
  type    = string
  default = "hcupnet-prod"
}

variable "cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/919fc107-bc87-48aa-9988-d1cef399b3e4"
}

variable "tennable_scanner_sg" {
  type    = string
  default = "sg-045253f618c437bef"
}
