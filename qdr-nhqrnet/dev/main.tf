terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "qdr-nhqrnet/dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/dev/terraform.tfstate"
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

locals {
  common_tags = {
    Environment = "dev"
    Location    = "us-east-1"
    Project     = "adass"

  }
}
module "tomcat" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "qpr-nhqrnet-tomcat-dev"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-036b352614304842d"#"ami-0ea0534e35f07caf4" # CIS CentOS 6
  instance_type           = "t2.micro"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  disk_space              = 10
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/qpr-nhqrnet/dev/tomcat"
  allow_tennable_scanner  = false
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
  override_private_ip                                = "10.37.3.173"
  tags = merge(local.common_tags, map("Name", "qdr-tomcat-dev"))
}

#resource "aws_network_interface_sg_attachment" "tennable_tomcat" {
#  security_group_id    = var.tennable_scanner_sg
#  network_interface_id = module.tomcat.primary_network_interface_id
#}

module "alb" {
  source                        = "../../modules/pantheon-alb"
  name                          = "qdr-dev"
  vpc_id                        = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids             = data.terraform_remote_state.vpc.outputs.pub_subnet_ids
  s3_bucket                     = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
  certificate_arn               = var.nhqrnet_cert_arn
  instance_ids                  = [module.tomcat.instance_id]
  ip_address_type               = "dualstack"
  alb_tg_instance_listener_port = 8080
  alb_target_group_port         = 80
  ssl_policy                    = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

resource "aws_lb_listener_certificate" "https" {
  listener_arn    = module.alb.aws_lb_listener_https_arn
  certificate_arn = var.iqdnet_cert_arn
}

resource "aws_security_group_rule" "alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.alb.security_group_id
  security_group_id        = module.tomcat.security_group_id
}

/*resource "aws_egress_only_internet_gateway" "tomcat" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "qpr-nhqrnet-tomcat-dev"
  }
}*/

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
