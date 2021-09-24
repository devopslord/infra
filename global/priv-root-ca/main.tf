terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "global/private-ca/terraform.tfstate"
    region = "us-east-1"
  }
}

/*
module "privateca" {
  source             = "../../modules/pantheon-acm-ca/v1/"
  expiration_in_days = 3649
  key_algorithm      = "RSA_2048"
  signing_algorithm  = "SHA256WITHRSA"
  subject = [{
    common_name         = "*.ahrq.gov"
    country             = "US"
    state               = "Maryland"
    locality            = "Rockville"
    organization        = "Agency for Healthcare Research and Quality"
    organizational_unit = "Testing"
  }]
}*/
