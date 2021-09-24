variable "awsconfig_name" {
  type = string
  default = "config"
}

variable "sns_arn" {
  type = string
  default = "arn:aws:sns:us-east-1:631203585119:hdasp-security"
}