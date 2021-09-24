variable "cloudtrailname" {
  type    = string
  default = "hdasp-cloudtrail"
}

variable "cloudtrail_loggroup_name" {
  type    = string
  default = "/hdasp/cloudtrail/"
}