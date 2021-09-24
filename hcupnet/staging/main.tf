terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "hcupnet/staging/terraform.tfstate"
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

locals {
  Name        = "hcupnet-staging"
  Environment = "staging"
  Project     = "adass"
  Location    = "us-east-1"
}

module "iis" {
  source                  = "../../modules/pantheon-ec2"
  name                    = var.name
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-05c7b993fcb48faaa" # CIS Microsoft Windows Server 2012 R2 Base
  instance_type           = "m5.large"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size          = 100
  disk_space              = 1000
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/hcupnet/staging/iis"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  project                                            = local.Project
  region                                             = local.Location
  environment                                        = local.Environment
}

#resource "aws_network_interface_sg_attachment" "tennable_iis" {
#  security_group_id    = var.tennable_scanner_sg
#  network_interface_id = module.iis.primary_network_interface_id
#}

module "alb" {
  source                        = "../../modules/pantheon-alb"
  name                          = var.name
  vpc_id                        = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnet_ids             = data.terraform_remote_state.vpc.outputs.pub_subnet_ids
  s3_bucket                     = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
  certificate_arn               = var.cert_arn
  instance_ids                  = [module.iis.instance_id]
  ip_address_type               = "dualstack"
  alb_tg_instance_listener_port = 80
  alb_target_group_port         = 80

}

resource "aws_security_group_rule" "alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.alb.security_group_id
  security_group_id        = module.iis.security_group_id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = module.alb.alb_arn
  port              = "8000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging_target_group.arn
  }
}

resource "aws_security_group_rule" "backend_sg_port" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  source_security_group_id = module.alb.security_group_id
  security_group_id        = module.iis.security_group_id
}

resource "aws_security_group_rule" "frontend_sg_port" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb.security_group_id
}

resource "aws_lb_target_group" "staging_target_group" {
  name     = "${var.name}-CustTempTrgGrp"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_lb_target_group_attachment" "staging_target_group" {

  target_group_arn = aws_lb_target_group.staging_target_group.arn
  target_id        = module.iis.instance_id
  port             = 8000
}

#---- below is a technical debt for rectoring at a later date --
resource "aws_lb_target_group" "staging_target_group_8001" {
  name     = "${var.name}-custom-port-grp"
  port     = 8001
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
}

resource "aws_lb_target_group_attachment" "staging_target_group_8001" {

  target_group_arn = aws_lb_target_group.staging_target_group_8001.arn
  target_id        = module.iis.instance_id
  port             = 8001
}

resource "aws_security_group_rule" "backend_sg_port_8001" {
  type                     = "ingress"
  from_port                = 8001
  to_port                  = 8001
  protocol                 = "tcp"
  source_security_group_id = module.alb.security_group_id
  security_group_id        = module.iis.security_group_id
}

resource "aws_security_group_rule" "frontend_sg_port_8001" {
  type              = "ingress"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.alb.security_group_id
}
resource "aws_lb_listener" "http_8001" {
  load_balancer_arn = module.alb.alb_arn
  port              = "8001"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.staging_target_group_8001.arn
  }
}
#--- end config for alb, tg, sg ---

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

#for new 2016 hcup server

module "iis_hcup_win_2016" {
  source         = "../../modules/pantheon-ec2"
  name           = "${var.name}_ewadass_2016"
  vpc_id         = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id         = "ami-027820228932da0bd" # CIS Microsoft Windows Server 2016 Base
  instance_type  = "t3.medium"
  ec2_key_name   = "pantheon"
  subnet_id      = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size = 30
  #disk_space              = 50
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/hcupnet/staging/iis_new"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  project                                            = local.Project
  region                                             = local.Location
  environment                                        = local.Environment
}


module "iis_hcup_win_2016_d_drive" {
  source = "../../modules/pantheon-ebs"
  availability_zone = module.iis_hcup_win_2016.availability_zone
  instance_id = module.iis_hcup_win_2016.instance_id
  name = "${var.name}_ewadass_2016"
  size = "50"
  device_name = "xvdg"
}
