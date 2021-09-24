variable "name" {
  type    = string
  default = "hcupnet-staging"
}

variable "cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/7ac5636f-a68f-4b44-9e90-28baaf72cdff"
}

variable "tennable_scanner_sg" {
  type    = string
  default = "sg-045253f618c437bef"
}

/*variable "target-group-arn" {
  type    = string
  default = "arn:aws:elasticloadbalancing:us-east-1:631203585119:targetgroup/hcupnet-staging/31368577e805f3e1"
}*/
