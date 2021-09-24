terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "meps/prod/terraform.tfstate"
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

locals {
  common_tags = {
    Environment = var.environment
    Location    = var.region
    Project     = var.project
  }
  meps_s3_static_data = {
    instance_role_arn="arn:aws:iam::631203585119:role/meps-tomcat-prod"
    instance_role_name="meps-tomcat-prod"
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

data "terraform_remote_state" "hcupnet" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "hcupnet/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "s3" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "meps/s3/terraform.tfstate"
    region = "us-east-1"
  }
}

module "tomcat" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "meps-tomcat-prod"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-036b352614304842d" # CIS CentOS 6
  instance_type           = "m4.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
  disk_space              = 150
  root_disk_size          = 100
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = true
  log_group               = "/meps/prod/tomcat"
  log_stream = [
    "/var/log/messages",
    "/var/log/secure",
    "/var/log/httpd/access_log",
    "/var/log/httpd/error_log",
    "/var/lib/apache-tomcat/logs/access_log",
    "/var/lib/apache-tomcat/logs/catalina.out"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment
}

#for sas troubleshooting
/*resource "aws_instance" "tomcat_prod_1" {
  ami = "ami-033e1606374df507e"
  instance_type = "t2.medium"
  key_name = "pantheon"
  iam_instance_profile = module.tomcat.instance_profile_name
  subnet_id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
  vpc_security_group_ids = ["sg-07365a4eec140acc6"]
  disable_api_termination = false
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
    volume_size = 30
  }

  tags = merge(local.common_tags, map("Name", "meps-tomcat-prod-1"))
}*/

module "iis" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "meps-iis-prod"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-05c7b993fcb48faaa" # CIS Microsoft Windows Server 2012 R2 Base
  instance_type           = "m5.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
  root_disk_size          = 100
  disk_space              = 150
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = true
  log_group               = "/meps/prod/iis"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment
}



resource "aws_security_group_rule" "hcupnet" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = data.terraform_remote_state.hcupnet.outputs.security_group_id
  security_group_id        = module.iis.security_group_id
}

resource "aws_security_group_rule" "tomcat" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = module.tomcat.security_group_id
  security_group_id        = module.iis.security_group_id
}

module "alb" {
  source            = "../../modules/pantheon-alb"
  name              = "meps-prod"
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.vpc.outputs.pub_subnet_ids
  s3_bucket         = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
  certificate_arn   = var.cert_arn
  instance_ids      = [module.tomcat.instance_id]
  ip_address_type               = "dualstack"
  alb_tg_instance_listener_port = 80
  alb_target_group_port         = 80
  ssl_policy                    = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

resource "aws_security_group_rule" "alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.alb.security_group_id
  security_group_id        = module.tomcat.security_group_id
}

resource "aws_security_group_rule" "albv6" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = module.alb.security_group_id
  to_port           = 80
  type              = "ingress"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "albv6ssl" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = module.alb.security_group_id
  to_port           = 443
  type              = "ingress"
  ipv6_cidr_blocks  = ["::/0"]
}

#---- attach s3 access policy to ec2 profile role assume role --
module "meps_s3_data_policy" {
  source = "../../modules/pantheon-s3-meps-policy/"
  policy_saved_location = "/adass/"
  instance_role_arn = local.meps_s3_static_data.instance_role_arn
  instance_role_name = local.meps_s3_static_data.instance_role_name
  policy_name = "${local.meps_s3_static_data.instance_role_name}-s3-policy"
  s3_bucket_arn = data.terraform_remote_state.s3.outputs.s3_web_static_data_arn

}