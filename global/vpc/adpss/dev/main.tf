terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpc/adpss/dev/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

#ADPSS PROD VPC For Peering
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/adpss/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source           = "../../../../modules/pantheon-vpc/v0.01"
  cidr_block       = "10.39.0.0/16"
  name             = var.name
  az_count         = 1
  eks_cluster_name = "hdasp-dev"
  environment = "dev"
  region = "us-east-1"
  project = "adpss"
}

# Outbound Connections for sftp.impaqint.com
resource "aws_network_acl_rule" "impaq" {
  network_acl_id = var.default_nacl_id
  rule_number    = 1
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "192.108.127.41/32"
}

# Outbound Connections for sftp.s-3.net
resource "aws_network_acl_rule" "sss" {
  network_acl_id = var.default_nacl_id
  rule_number    = 2
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "198.136.164.212/32"
}

# Outbound Connections for eft.ahrq.gov
resource "aws_network_acl_rule" "ahrq" {
  network_acl_id = var.default_nacl_id
  rule_number    = 3
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "162.99.46.83/32"
}

# Internal VPC Outbound Connections
resource "aws_network_acl_rule" "vpc" {
  network_acl_id = var.default_nacl_id
  rule_number    = 4
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.39.0.0/16"
}

# Tenable Scanner VPC
/*resource "aws_network_acl_rule" "tenable_scanner" {
  network_acl_id = var.default_nacl_id
  rule_number    = 5
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.31.1.0/24"
}*/

# Prod VPC Outbound Connections
/*resource "aws_network_acl_rule" "prod" {
  network_acl_id = var.default_nacl_id
  rule_number    = 6
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.38.0.0/16"
}*/


module "pcx" {
  source = "../../../../modules/pantheon-pcx/"

  vpc_id          = module.vpc.vpc_id #requester
  peer_vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block      = module.vpc.cidr_block
  peer_cidr_block = data.terraform_remote_state.vpc.outputs.cidr_block
  route_table_ids = [
    module.vpc.priv_route_table_id,
    module.vpc.pub_route_table_id
  ]
  peer_route_table_ids = [
    data.terraform_remote_state.vpc.outputs.priv_route_table_id,
    data.terraform_remote_state.vpc.outputs.pub_route_table_id
  ]
}
