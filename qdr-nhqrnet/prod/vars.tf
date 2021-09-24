variable "nhqrnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/d54cf3e1-4912-40c9-a48d-f7635fc00405"
}

variable "iqdnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/eb269a81-101a-4562-a1f6-de12f8f17ad0"
}

variable "ahrqivedhcupnet_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/eeb789a0-efb3-4218-a7d5-6e811acf7e0b"
}

variable "statesnapshots_cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/c78beb9a-0e8a-4ff6-9618-821758249ab5"
}

variable "tennable_scanner_sg" {
  type    = string
  default = "sg-045253f618c437bef"
}
