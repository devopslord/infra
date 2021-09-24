terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/waf/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

# Setup manually for now in AWS Console
# Need to wait for waf2 to be implemented in terraform
# https://github.com/terraform-providers/terraform-provider-aws/issues/11046#issuecomment-562632816
