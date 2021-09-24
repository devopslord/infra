terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpc/dev/terraform.tfstate"
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

module "vpc" {
  source                           = "../../../modules/pantheon-vpc/v0.02"
  cidr_block                       = "10.37.0.0/16"
  name                             = var.name
  az_count                         = 3
  eks_cluster_name                 = "hdasp"
  eip                              = "eipalloc-6fdc1a08" #availing unused EIP
  assign_generated_ipv6_cidr_block = true
  region = "us-east-1"
  project = "adass"
  environment = "dev"
}

module "pcx" {
  source = "../../../modules/pantheon-pcx/"

  vpc_id          = module.vpc.vpc_id
  peer_vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  cidr_block      = module.vpc.cidr_block
  peer_cidr_block = data.terraform_remote_state.vpc.outputs.cidr_block
  route_table_ids = [
    module.vpc.priv_route_table_id,
    module.vpc.pub_route_table_id
  ]
  peer_route_table_ids = [
    data.terraform_remote_state.vpc.outputs.priv_route_table_id,
    data.terraform_remote_state.vpc.outputs.pub_route_table_id
  ]
}

module "pcx-to-staging" {
  source = "../../../modules/pantheon-pcx/"

  vpc_id          = module.vpc.vpc_id
  peer_vpc_id     = "vpc-0dbc05ee53242ec9e"
  cidr_block      = module.vpc.cidr_block
  peer_cidr_block = "10.36.0.0/16"
  route_table_ids = [
    module.vpc.priv_route_table_id,
    module.vpc.pub_route_table_id
  ]
  peer_route_table_ids = [
    "rtb-071ad3890e44bf627","rtb-04ea1dd2d2b7bd342"
  ]
}

resource "aws_db_subnet_group" "main" {
  name       = var.name
  subnet_ids = module.vpc.priv_subnet_ids

  tags = {
    Name = var.name
  }
}

resource "aws_s3_bucket" "main" {
  bucket = "hdasp-${var.name}-alb-logs"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_caller_identity" "main" {}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.main.arn}/*/AWSLogs/${data.aws_caller_identity.main.account_id}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.main.arn}/*/AWSLogs/${data.aws_caller_identity.main.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.main.arn
      }
    ]
  })
}
