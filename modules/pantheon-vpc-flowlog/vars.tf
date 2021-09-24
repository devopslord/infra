
variable "name" {
  type        = string
  description = "The VPC Flowlog name"
}
variable "username" {
  type        = string
  description = "The user to attach the trust policy"
}

variable "log_group" {
  type        = string
  description = "Required field for logging cloudwatch logs in the log group (ex:adpss/vpc/dev)"
}

variable "vpc_id" {
  type = string
}

variable "log_format" {
  type        = string
  default     = "version vpc-id subnet-id instance-id interface-id account-id type srcaddr dstaddr srcport dstport pkt-srcaddr pkt-dstaddr protocol bytes packets start end action tcp-flags log-status"
  description = "Provide any custom log format to log the traffic"
}

variable "environment" {
  type        = string
  description = "Set the environment - Dev or Prod for tagging"
}