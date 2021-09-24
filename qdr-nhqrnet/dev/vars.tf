variable "nhqrnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/5735fedc-e16b-4906-94bb-3c988090c753"
}

variable "iqdnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/5398add3-3475-4227-956b-296419bdfe6b"
}

variable "tennable_scanner_sg" {
  type    = string
  default = "na"
}
