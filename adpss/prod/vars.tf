variable "name" {
  type    = string
  default = "adpss"
}
variable "environment" {
  type    = string
  default = "production"
}

variable "hostname" {
  default = "IP-0A2601E4"
}

variable "disk_drives" {
  type    = list(string)
  default = ["C:", "H:", "M:", "P:", "O:"]
}

variable "subscribers" {
  type    = list(string)
  default = ["schadalavada@panth.com", "jduffus@panth.com", "rjeevagan@panth.com"]
}

//for tagging resources purpose
variable "project" {
  type    = string
  default = "adpss"
}

variable "region" {
  type    = string
  default = "us-east-1"
}