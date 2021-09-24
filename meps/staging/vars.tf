variable "cert_arn" {
  type    = string
  default = "arn:aws:acm:us-east-1:631203585119:certificate/0e90f0be-193b-4048-8eb0-d394fb30025b"
  //"arn:aws:acm:us-east-1:631203585119:certificate/067d55c9-c6ff-4db9-a580-13d83878330c"
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
  default = "staging"
}