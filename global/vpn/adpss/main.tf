terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpn/adpss/terraform.tfstate"
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
    key    = "global/vpc/adpss/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpn" {
  source          = "../../../modules/pantheon-vpn/"
  name            = "adpss"
  split_tunnel    = true
  server_cert_arn = "arn:aws:acm:us-east-1:631203585119:certificate/baf2d434-416d-41a2-98dd-8904e8828e01"
  client_cert_arn = "arn:aws:acm:us-east-1:631203585119:certificate/159403fb-4509-49be-8b19-d4fd3fe30431"
  subnet_id       = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
}
