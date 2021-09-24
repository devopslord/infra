terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "qdr-nhqrnet/prod/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

locals {
  common_tags = {
    Environment = "production"
    Location    = "us-east-1"
    Project     = "adass"

  }
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

module "tomcat" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "qpr-nhqrnet-tomcat-prod"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-036b352614304842d" # CIS CentOS 6
  instance_type           = "m4.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  disk_space              = 200
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = true
  log_group               = "/qpr-nhqrnet/prod/tomcat"
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
  project                                            = local.common_tags.Project
  region                                             = local.common_tags.Location
  environment                                        = local.common_tags.Environment
}

module "alb" {
  source            = "../../modules/pantheon-alb"
  name              = "qdr-prod"
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.vpc.outputs.pub_subnet_ids
  s3_bucket         = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
  certificate_arn   = var.nhqrnet_cert_arn
  instance_ids      = [module.tomcat.instance_id]
  ip_address_type               = "dualstack"
  alb_tg_instance_listener_port = 80
  alb_target_group_port         = 80
  ssl_policy                    = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

resource "aws_lb_listener_certificate" "iqdnet" {
  listener_arn    = module.alb.aws_lb_listener_https_arn
  certificate_arn = var.iqdnet_cert_arn
}

resource "aws_lb_listener_certificate" "ahrqivedhcupnet" {
  listener_arn    = module.alb.aws_lb_listener_https_arn
  certificate_arn = var.ahrqivedhcupnet_cert_arn
}

resource "aws_lb_listener_certificate" "statesnapshots" {
  listener_arn    = module.alb.aws_lb_listener_https_arn
  certificate_arn = var.statesnapshots_cert_arn
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

module "tomcat_green_from_prod_ami" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "qpr-nhqrnet-tomcat-prod-green-instance-from-prod"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-041ceae9b5dbe8100" # CIS CentOS 6 (from latest ami as of 12/28/2020)
  instance_type           = "m4.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  disk_space              = 35
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = true
  log_group               = "/qpr-nhqrnet/prod/tomcat/green/prod"
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
  project                                            = local.common_tags.Project
  region                                             = local.common_tags.Location
  environment                                        = local.common_tags.Environment
}

resource "aws_security_group_rule" "tomcat_green_from_prod_ami" {
  from_port         = 1521
  protocol          = "tcp"
  security_group_id = "sg-08b8971097e99bacc"
  to_port           = 1521
  type              = "ingress"
  source_security_group_id = module.tomcat_green_from_prod_ami.security_group_id

}