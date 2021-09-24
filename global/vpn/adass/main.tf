terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpn/adass/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpn" {
  source          = "../../../modules/pantheon-vpn/"
  name            = "adass"
  split_tunnel    = true
  server_cert_arn = "arn:aws:acm:us-east-1:631203585119:certificate/2edef6a8-11dd-4040-b8a3-3bdf62513209"
  client_cert_arn = "arn:aws:acm:us-east-1:631203585119:certificate/451ab142-09be-4441-b3cb-a84308a7b4fa"
  subnet_id       = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
}
