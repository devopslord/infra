variable "policy_name" {
  type = string
}
#EX: /adass/
variable "policy_saved_location" {
  type = string
  default = ""
}

variable "instance_role_arn" {
  type = string
}

variable "instance_role_name" {
  type = string
}

variable "s3_bucket_arn" {
  type = string
}