terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/s3/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "hdasp-terraform-state"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "playbooks" {
  bucket = "hdasp-inventory-playbooks"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}