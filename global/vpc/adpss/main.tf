terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpc/adpss/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

module "vpc" {
  source           = "../../../modules/pantheon-vpc/v0.01"
  cidr_block       = "10.38.0.0/16"
  name             = var.name
  az_count         = 1
  eks_cluster_name = "hdasp"
  environment      = "production"
  region           = "us-east-1"
  project          = "adpss"
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
  cidr_block     = "10.38.0.0/16"
}

# Tenable Scanner VPC
resource "aws_network_acl_rule" "tenable_scanner" {
  network_acl_id = var.default_nacl_id
  rule_number    = 5
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.31.1.0/24"
}

# Dev VPC Outbound Connections
/*resource "aws_network_acl_rule" "dev" {
  network_acl_id = var.default_nacl_id
  rule_number    = 6
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.39.0.0/16"
}*/

resource "aws_network_acl_rule" "sentinelone_virus_updates_ip1" {
  network_acl_id = var.default_nacl_id
  rule_number    = 11
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "54.211.159.31/32"
}

resource "aws_network_acl_rule" "sentinelone_virus_updates_ip2" {
  network_acl_id = var.default_nacl_id
  rule_number    = 12
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "54.86.162.34/32"
}