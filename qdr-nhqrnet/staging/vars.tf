variable "nhqrnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/fd995597-63cd-4c2c-a824-90749c562452"
}

variable "iqdnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/e922128c-d802-4a0d-afcf-2e7ed8e1e326"
}

variable "tennable_scanner_sg" {
  type    = string
  default = "sg-045253f618c437bef"
}
