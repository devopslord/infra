variable "slack_webhook_url" {
  type    = string
  default = "https://hooks.slack.com/services/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" # This is the webhook for #hosting-alerts channel
}

variable "low_disk_space_critical_duration" {
  type    = number
  default = 1
}

variable "low_disk_space_critical_value" {
  type    = number
  default = 10
}

variable "low_disk_space_warning_duration" {
  type    = number
  default = 2
}

variable "low_disk_space_warning_value" {
  type    = number
  default = 30
}

variable "high_cpu_usage_critical_duration" {
  type    = number
  default = 5
}

variable "high_cpu_usage_critical_value" {
  type    = number
  default = 90
}

variable "high_cpu_usage_warning_duration" {
  type    = number
  default = 10
}

variable "high_cpu_usage_warning_value" {
  type    = number
  default = 70
}

variable "high_mem_usage_critical_duration" {
  type    = number
  default = 5
}

variable "high_mem_usage_critical_value" {
  type    = number
  default = 95
}

variable "high_mem_usage_warning_duration" {
  type    = number
  default = 10
}

variable "high_mem_usage_warning_value" {
  type    = number
  default = 75
}

variable "not_reporting_critical_duration" {
  type    = number
  default = 5
}
