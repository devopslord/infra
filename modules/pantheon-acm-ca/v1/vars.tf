variable "subject" {
  type = list(object({
    common_name         = string
    country             = string
    state               = string
    locality            = string
    organizational_unit = string
    organization        = string
  }))
  default = [{
    common_name         = "*.ahrq.gov"
    country             = "US"
    state               = "Maryland"
    locality            = "Rockville"
    organization        = "Agency for Healthcare Research and Quality"
    organizational_unit = "Testing"
  }]
}

variable "key_algorithm" {
  type    = string
  default = "RSA_2048"
}

variable "signing_algorithm" {
  type    = string
  default = "SHA256WITHRSA"
}

variable "expiration_in_days" {
  type    = number
  default = 3649
}