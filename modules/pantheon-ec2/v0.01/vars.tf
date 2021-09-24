variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "sg_outbound_cidr_blocks" {
  type = list
  default = [
    "0.0.0.0/0"
  ]
}

variable "ami_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "ec2_key_name" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "root_disk_size" {
  type    = number
  default = 30
}

variable "ebs_volume" {
  type    = bool
  default = true
}

variable "disk_space" {
  type    = string
  default = 30
}

variable "disable_api_termination" {
  type    = bool
  default = false
}

variable "log_group" {
  type = string
}

variable "log_stream" {
  type = list
}

variable "cloudwatch_log_subscription_filter_role_arn" {
  type = string
}

variable "cloudwatch_log_subscription_filter_destination_arn" {
  type = string
}

variable "vpn_security_group_id" {
  default = null
}

variable "allow_tennable_scanner" {
  type    = bool
  default = false
}

variable "tennable_scanner_sg_id" {
  type    = string
  default = "sg-045253f618c437bef"
}

variable "override_private_ip" {
  type    = string
  default = null
}

variable "associate_public_ip" {
  type    = bool
  default = false
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

variable "instance_profile_name" {
  type = string
  description = "A required existing instance profile to use. If not use root pantheon-ec2 module and not v0.01"
}


variable "ec2_security_group_id" {
  type = string
  default = ""
  description = "To reuse existing securitygroup of ec2 enter security group id."
}

variable "ec2_userdata" {
  type = string
  default = ""
  description = "(Optional): Supply User data scripts if needed to bootstrap."
}