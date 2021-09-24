variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "source_security_group_id" {
  type = list
}

variable "allocated_storage" {
  type = number
}

variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}

variable "availability_zone" {
  type = string
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "copy_tags_to_snapshot" {
  type    = bool
  default = true
}

variable "db_subnet_group_name" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "engine" {
  type = string
}

variable "engine_version" {
  type = string
}

variable "instance_class" {
  type = string
}

variable "license_model" {
  type = string
}

variable "max_allocated_storage" {
  type = number
}

variable "password" {
  type = string
}

variable "skip_final_snapshot" {
  type    = bool
  default = false
}

variable "storage_encrypted" {
  type    = bool
  default = true
}

variable "storage_type" {
  type    = string
  default = "gp2"
}

variable "username" {
  type    = string
  default = "admin"
}
