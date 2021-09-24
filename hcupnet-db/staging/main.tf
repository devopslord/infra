terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "hcupnet-db/staging/terraform.tfstate"
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

module "db" {
  source                = "../../modules/pantheon-rds"
  name                  = var.name
  vpc_id                = data.terraform_remote_state.vpc.outputs.vpc_id
  allocated_storage     = 100
  availability_zone     = data.terraform_remote_state.hcupnet.outputs.availability_zone
  db_subnet_group_name  = data.terraform_remote_state.vpc.outputs.db_subnet_group_name
  engine                = "sqlserver-se"
  engine_version        = "12.00.6293.0.v1"
  instance_class        = "db.r5.large"
  license_model         = "license-included"
  max_allocated_storage = 5000
  password              = var.passwd
  source_security_group_id = [
    data.terraform_remote_state.vpn.outputs.vpn_security_group_id,
    data.terraform_remote_state.hcupnet.outputs.security_group_id
  ]
}
