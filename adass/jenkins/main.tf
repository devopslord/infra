# Remote State
terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "adass/dev/jenkins/terraform.tfstate"
    region = "us-east-1"
  }
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

resource "aws_iam_policy" "jenkins" {
  name = "${var.jenkins_name}-ec2-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action = [
          "ec2:GetConsoleOutput",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeRegions",
          "ec2:DescribeImages",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "SidForJenkinsOnHDASP"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "jenkins" {
  policy_arn = aws_iam_policy.jenkins.arn
  role       = module.jenkins.role_name

}
resource "aws_iam_policy" "asg" {
  name = "${var.jenkins_name}-asg-access-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action = [
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:CreateLaunchTemplateVersion"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "SidForASGGrupHDASP"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "asg" {
  policy_arn = aws_iam_policy.asg.arn
  role       = module.jenkins.role_name

}


module "jenkins" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = var.jenkins_name
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = var.jenkins_linux_ami
  #root_disk_size          = 30
  instance_type           = "t2.medium"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.pub_subnet_ids[2]
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  log_group               = "/adass/dev/jenkins"
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
  override_private_ip = "10.37.30.242"
  associate_public_ip = true
  environment = "dev"
  region = "us-east-1"
  project = "adass"
}
#null resource is required to add additional trusted entities for jenkins to talk to
resource "null_resource" "jenkins" {
  provisioner "local-exec" {
    command = "aws iam update-assume-role-policy --role-name hdasp-jenkins --policy-document file://hdasp_jenkins_assume_role.json"
  }

  depends_on = [module.jenkins.role_arn]
}

#resource "aws_network_interface_sg_attachment" "tennable_tomcat" {
#  security_group_id    = var.tennable_scanner_sg
#  network_interface_id = module.tomcat.primary_network_interface_id
#}


resource "aws_security_group" "jenkins" {
  name        = "${var.jenkins_name}-public-ingress"
  description = "Used for access to the public instances"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  dynamic "ingress" {
    for_each = var.external_ports
    content {
      description = "allow bitbucket webhooks"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.bitbucket_cidrblock
    }
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, map("Name", "${var.jenkins_name}"))
}


resource "aws_network_interface_sg_attachment" "bitbucket_access" {
  security_group_id    = aws_security_group.jenkins.id
  network_interface_id = module.jenkins.primary_network_interface_id
}


#jenkins wind node slave for testing and configuration only. Or, can be used to provision permanent slave node for jenkins
/*resource "aws_instance" "winslave" {
  ami = "ami-013bdf60d9c7aab24" #windows slave with critical patch updates
  instance_type = "t2.medium"
  key_name = "jenkins"
  iam_instance_profile = module.jenkins.instance_profile_name
  subnet_id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  vpc_security_group_ids = ["sg-0d5570227b55367d4"]
  disable_api_termination = false
  user_data = data.template_file.winslave.rendered
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
    volume_size = 30
  }
  tags = merge(local.common_tags, map("Name", "${var.jenkins_name}-win-slavep"))
}*/

data "template_file" "winslave" {
  template = "${file("${path.module}/userdata.tpl")}"
}

# to test jenkins linux master ami
/* resource "aws_instance" "linuxslave" {
  ami = "ami-0be2609ba883822ec" #"ami-036b352614304842d"
  instance_type = "t2.small"
  key_name = "jenkins"
  iam_instance_profile = module.jenkins.instance_profile_name
  subnet_id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  vpc_security_group_ids = ["sg-0d5570227b55367d4"]
  disable_api_termination = false
  #associate_public_ip_address = true
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
    volume_size = 10
  }
  tags = merge(local.common_tags, map("Name", "${var.jenkins_name}-slave-lnx"))
}*/


/*resource "aws_instance" "qdr_test_compl_tomcat" {
  ami = "ami-0be36d98480dfdf80"
  instance_type = "t2.medium"
  key_name = "pantheon"
  iam_instance_profile = module.jenkins.instance_profile_++-name
  subnet_id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  vpc_security_group_ids = ["sg-0d5570227b55367d4"]
  disable_api_termination = false
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
    volume_size = 20
  }
  private_ip = "10.37.3.185"
  tags = merge(local.common_tags, map("Name", "qdr_test_compl_tomcat"))
}*/

