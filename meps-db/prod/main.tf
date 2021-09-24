terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "meps-db/prod/terraform.tfstate"
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

data "terraform_remote_state" "meps" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "meps/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "qdr-nhqrnet" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "qdr-nhqrnet/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

module "db" {
  source                = "../../modules/pantheon-rds"
  name                  = var.name
  vpc_id                = data.terraform_remote_state.vpc.outputs.vpc_id
  allocated_storage     = 100
  availability_zone     = data.terraform_remote_state.meps.outputs.tomcat_availability_zone
  db_subnet_group_name  = data.terraform_remote_state.vpc.outputs.db_subnet_group_name
  engine                = "oracle-se2"
  engine_version        = "12.2.0.1.ru-2019-10.rur-2019-10.r1"
  instance_class        = "db.r5.2xlarge"
  license_model         = "license-included"
  max_allocated_storage = 1600
  password              = var.passwd
  source_security_group_id = [
    data.terraform_remote_state.vpn.outputs.vpn_security_group_id,
    data.terraform_remote_state.meps.outputs.tomcat_security_group_id,
    data.terraform_remote_state.meps.outputs.iis_security_group_id,
    data.terraform_remote_state.qdr-nhqrnet.outputs.security_group_id
  ]
}
