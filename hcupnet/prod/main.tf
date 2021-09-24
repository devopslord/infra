terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "hcupnet/prod/terraform.tfstate"
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

data "terraform_remote_state" "vpn" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpn/adass/terraform.tfstate"
    region = "us-east-1"
  }
}

module "iis" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = var.name
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-05c7b993fcb48faaa" # CIS Microsoft Windows Server 2012 R2 Base
  instance_type           = "m5.xlarge"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size          = 100
  disk_space              = 1000
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = true
  log_group               = "/hcupnet/prod/iis"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
}

module "alb" {
  source            = "../../modules/pantheon-alb"
  name              = var.name
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.vpc.outputs.pub_subnet_ids
  s3_bucket         = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
  certificate_arn   = var.cert_arn
  instance_ids      = [module.iis.instance_id]
}

resource "aws_security_group_rule" "alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.alb.security_group_id
  security_group_id        = module.iis.security_group_id
}
