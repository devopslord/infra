terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpn/us_west/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}


provider "aws" {
  version = "~> 2.0"
  region  = "us-west-1"
  profile = "hdasp"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/adpss/us_west/terraform.tfstate"
    region = "us-east-1"
  }
}



resource "aws_acm_certificate" "adpss_server" {
  certificate_chain = file("../../../global/vpn/adpss_dr/certs/ca.pem")
  certificate_body = file("../../../global/vpn/adpss_dr/certs/vpn.adpss.network.pem")
  private_key = file("../../../global/vpn/adpss_dr/certs/vpn.adpss.network.key")
}

resource "aws_acm_certificate" "adpss_client" {
  certificate_chain = file("../../../global/vpn/adpss_dr/certs/ca.pem")
  certificate_body = file("../../../global/vpn/adpss_dr/certs/vpn.adpss.client.pem")
  private_key = file("../../../global/vpn/adpss_dr/certs/vpn.adpss.client.key")
}


module "vpn" {
  source          = "../../../modules/pantheon-vpn/"
  name            = "adpss"
  split_tunnel    = true
  server_cert_arn = aws_acm_certificate.adpss_server.arn
  client_cert_arn = aws_acm_certificate.adpss_client.arn
  subnet_id       = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_ec2_client_vpn_authorization_rule" "example" {
  client_vpn_endpoint_id = module.vpn.client_vpn_endpoint_id
  target_network_cidr    = data.terraform_remote_state.vpc.outputs.cidr_block
  authorize_all_groups   = true

  depends_on = [module.vpn]
}
