# Remote State
terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "meps/dev/terraform.tfstate"
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
    Environment = "dev"
    Location    = "us-east-1"
    Project     = "adass"

  }
  s3 = {
    BucketName  = "adass-meps-static-webcontent"
    sourc_ips = ["10.37.3.44/32","10.36.2.84/32"]
    arn = "arn:aws:s3:::adass-meps-static-webcontent"
  }
  meps_s3_static_data = {
    instance_role_arn="arn:aws:iam::631203585119:role/hdasp-jenkins"
    instance_role_name="hdasp-jenkins"
  }
  name = "meps"
}


resource "aws_instance" "meps_dev_tomcat" {
  ami = "ami-036b352614304842d"
  instance_type = "t2.small"
  key_name = "pantheon"
  iam_instance_profile = local.meps_s3_static_data.instance_role_name
  subnet_id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  vpc_security_group_ids = ["sg-0d5570227b55367d4"]
  disable_api_termination = false
  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
    volume_size = 15
  }
  private_ip = "10.37.3.44"

  tags = merge(local.common_tags, map("Name", "meps-tomcat-dev"))
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

resource "aws_instance" "meps_dev_centos8_tomcat" {
  ami = "ami-0a7eb3ddf1c0c503e"
  instance_type = "t2.small"
  key_name = "pantheon"
  iam_instance_profile = local.meps_s3_static_data.instance_role_name
  subnet_id = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2]
  vpc_security_group_ids = ["sg-0d5570227b55367d4"]
  disable_api_termination = false

  ebs_block_device {
    device_name = "/dev/xvda"
    volume_type = "gp2"
    delete_on_termination = true
    encrypted = true
    volume_size = 15
  }
  private_ip = "10.37.3.46"

  tags = merge(local.common_tags, map("Name", "meps-tomcat-dev-centos8"))
}
