# Remote State
terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "meps/asg/prod/terraform.tfstate"
    region = "us-east-1"
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

data "aws_subnet_ids" "meps_vpc_sn" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

data "terraform_remote_state" "ca" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/private-ca/terraform.tfstate"
    region = "us-east-1"
  }
}

/* UNCOMMENT BELOW CODE TO IMPLEMENT ASG FOR MEPS*/
/*
locals {
  meps = {
    name = "meps-asg-green"
    ami_id = "ami-0a0d9f2c31d2668c0"
    vpn_sg_id = "sg-0ff0ce5005706c4ba"
    db_sg_id = "sg-08b8971097e99bacc" #"sg-06c4654d6599daa59"
    environment = "prod"

    s3 = {
      static_content_bucket_arn = "arn:aws:s3:::adass-meps-static-webcontent"
    }
  }

}

#------------------------- POLICIES ROLES -------------------------
#meps static s3 bucket - IAM Policy
resource "aws_iam_policy" "meps_static_data" {
  name        = "${local.meps.name}-static-webcontent-policy"
  description = "This policy is to allow MEPS Server Instance Profile Access To S3 bucket for MEPS Static Content purposes."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid      = "AllowEC2MEPSCLIToMakeSTSCallsOnInstanceRole",
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource =  module.asg.asg_role_arn #aws_iam_role.asg.arn
      },
      {
        Sid    = "AllowMEPSEC2ToListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = local.meps.s3.static_content_bucket_arn
      },
      {
        Sid    = "AllowMEPSEC2ToListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:HeadBucket"
        ]
        Resource = local.meps.s3.static_content_bucket_arn
      },
      {
        Sid    = "AllowMEPSEC2ToListBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = ["${local.meps.s3.static_content_bucket_arn}*//*"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = aws_iam_policy.meps_static_data.arn
  role = module.asg.asg_role_name

  depends_on = [module.asg]
}


#------------------------- ASG Module -------------------------

data "aws_subnet" "cicd" {
  id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1]
}

module "asg" {
  source = "../../../modules/pantheon-asg-ec2"
  enable_autoscaling = true
  name = local.meps.name
  enviornment = local.meps.environment
  private_subnet_ids = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0],data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1],data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]]
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
  #alb_security_group_id = coalesce(aws_security_group.alb_sg.id)
  launch_template = {
    image_id       = local.meps.ami_id
    instance_type  = "t2.small"
    ebs_optimized  = "false"
    key_name       = "pantheon"
    resource_type  = "instance"
    launch_version = "$Latest"
    disable_instance_termination = false
    attached_volume_size = 150
    root_volume_size = 100
  }
  vpn_security_group_id = local.meps.vpn_sg_id
  database_security_group_id = local.meps.db_sg_id
  cicd_subnet_id= data.aws_subnet.cicd.id
  cicd_private_ip = cidrhost(data.aws_subnet.cicd.cidr_block, 28)
}

#----------------------------- ***************** ------------------------------

#----------------------------- ALB ------------------------------
resource "aws_security_group" "alb_sg" {
  name   = "${local.meps.name}-alb-sg"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "webserver_alb_sg_rule" {
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = module.asg.webserver_sg_id
  to_port                  = 80
  type                     = "ingress"
  source_security_group_id = aws_security_group.alb_sg.id

  depends_on = [aws_security_group.alb_sg, module.asg]
}


resource "aws_lb" "alb" {
  name               = "${local.meps.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [data.terraform_remote_state.vpc.outputs.pub_subnet_ids[0],
    data.terraform_remote_state.vpc.outputs.pub_subnet_ids[1],
    data.terraform_remote_state.vpc.outputs.pub_subnet_ids[2]]
  idle_timeout               = 10
  enable_deletion_protection = true
  enable_http2               = true
  ip_address_type            = "dualstack"
  access_logs {
    bucket  = data.terraform_remote_state.vpc.outputs.alb_logs_s3_bucket
    prefix  = "${local.meps.name}-alb"
    enabled = true
  }

  depends_on = [aws_security_group.alb_sg]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  depends_on = [module.asg]
}


resource "aws_acm_certificate" "alb" {
  domain_name               = "${local.meps.name}.ahrq.gov"
  certificate_authority_arn = data.terraform_remote_state.ca.outputs.private_ca_arn

  depends_on = [data.terraform_remote_state.ca]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = module.asg.asg_targetgroup_arn

  }
  depends_on = [aws_acm_certificate.alb,  module.asg]
}*/







