terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpc/adpss/us_west/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-west-1"
  profile = "hdasp"
}

variable "az_map" {
  type = map
  default = {
    0 = "us-west-1c",
    1 = "us-west-1b"
  }
}

module "vpc" {
  source           = "../../../modules/pantheon-vpc/v0.01"
  cidr_block       = "10.38.0.0/16"
  name             = var.name
  az_count         = 1
  az_map = var.az_map
  eks_cluster_name = "hdasp"
  environment = "production"
  region = "us-west-1"
  project = "adpss"
}


