terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "meps/staging/terraform.tfstate"
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
    key    = "global/vpc/staging/terraform.tfstate"
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

data "terraform_remote_state" "hcupnet" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "hcupnet/staging/terraform.tfstate"
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

locals {
  common_tags = {
    Environment = var.environment
    Location    = var.region
    Project     = var.project
  }
  name = "meps-staging"
  meps_s3_static_data = {
    instance_role_arn="arn:aws:iam::631203585119:role/meps-tomcat-staging"
    instance_role_name="meps-tomcat-staging"
  }

}
#ami_id                  = "ami-036b352614304842d" # CIS CentOS 6 old staging ami
module "tomcat" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "meps-tomcat-staging"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-036b352614304842d" # CIS CentOS 6
  instance_type           = "m4.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
  disk_space              = 150
  root_disk_size          = 100
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/meps/staging/tomcat"
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
# Added by lucky ---begin
module "tomcatcentos8" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "meps-tomcatcentos8-staging"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-04e43d19fd4c6d0be" # CIS CentOS 8
  instance_type           = "m4.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
  disk_space              = 150
  root_disk_size          = 100
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/meps/staging/tomcatcentos8"
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
resource "aws_security_group_rule" "tomcatcentos8" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = module.tomcatcentos8.security_group_id
  security_group_id        = module.iis.security_group_id
}
module "albcentos8" {
  source            = "../../modules/pantheon-alb"
  name              = "meps-staging-centos8"
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids = data.terraform_remote_state.vpc.outputs.pub_subnet_ids
  s3_bucket         = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
  certificate_arn   = var.cert_arn
  instance_ids      = [module.tomcatcentos8.instance_id]
  ip_address_type               = "dualstack"
  alb_tg_instance_listener_port = 80
  alb_target_group_port         = 80
  ssl_policy                    = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
}

resource "aws_security_group_rule" "albcentos8" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.albcentos8.security_group_id
  security_group_id        = module.tomcatcentos8.security_group_id
}

#--allow access to meps iis staging server to access tomcat
resource "aws_security_group_rule" "iis_tomcatcentos8_allow" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  source_security_group_id = module.iis.security_group_id
  security_group_id        = module.tomcatcentos8.security_group_id
}

resource "aws_security_group_rule" "albcentos8v6" {
  from_port         = 80
  protocol          = "tcp"
  security_group_id = module.albcentos8.security_group_id
  to_port           = 80
  type              = "ingress"
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "albcentos8v6ssl" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = module.albcentos8.security_group_id
  to_port           = 443
  type              = "ingress"
  ipv6_cidr_blocks  = ["::/0"]
}

# Added by lucky ---end

module "iis" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "meps-iis-staging"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-05c7b993fcb48faaa" # CIS Microsoft Windows Server 2012 R2 Base
  instance_type           = "m5.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
  root_disk_size          = 100
  disk_space              = 150
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/meps/staging/iis"
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

# Added by lucky ---begin

# Added by lucky --end
module "alb" {
  source            = "../../modules/pantheon-alb"
  name              = "meps-staging"
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

#--allow access to meps iis staging server to access tomcat
resource "aws_security_group_rule" "iis_tomcat_allow" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "TCP"
  source_security_group_id = module.iis.security_group_id
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