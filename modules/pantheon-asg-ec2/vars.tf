variable "name" {
  type = string
}

variable "enviornment" {
  type    = string
  default = "green"
}

variable "vpc_id" {
  type        = string
  description = "required to launch the autoscaling gruop"
}

variable "vpn_security_group_id" {
  type        = string
  description = "required pass vpn security group id for vpn based reachability"

}

variable "database_security_group_id" {
  type        = string
  description = "Required rule to webserver access database"

}


/*variable "alb_security_group_id" {
  type        = string
  description = "If set to alb security group id, adds a rule allowing alb to access webserver on port 80"
}*/


variable "enable_autoscaling" {
  description = "If set to true, enables autoscaling"
  type        = bool
}

variable "launch_template" {
  type = object({
    image_id       = string
    instance_type  = string
    ebs_optimized  = string
    key_name       = string
    resource_type  = string
    launch_version = string
    disable_instance_termination = bool
    attached_volume_size = number
    root_volume_size = number
  })
}

variable "private_subnet_ids" {
  type = list
}

variable "cicd_private_ip" {
  type = string
  default = null
  description = "This is optional. To use in conjuction with Jenkins CICD Pipeline"
}

variable "cicd_subnet_id" {
  type = string
  default = null
  description = "This is optional"

}