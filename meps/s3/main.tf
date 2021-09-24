terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "meps/s3/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}


locals {
  common_tags = {
    Environment = "prod"
    Location    = "us-east-1"
    Project     = "adass"

  }
  s3 = {
    bucket_name  = "adass-meps-static-webcontent"
    source_ips = ["10.37.3.44/32","10.36.2.84/32"]
    arn = "arn:aws:s3:::adass-meps-static-webcontent"
  }
  instance_role_arn="arn:aws:iam::631203585119:role/hdasp-jenkins"
}

resource "aws_s3_bucket" "web_static_data" {
  bucket = local.s3.bucket_name

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  acl                 = "private"
  force_destroy       = false
  tags                = local.common_tags

}

resource "aws_s3_bucket_public_access_block" "web_static_data" {
  bucket = aws_s3_bucket.web_static_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "web_static_data" {
  bucket = aws_s3_bucket.web_static_data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowMepsJenkinsRoleToReadTheBucket"
        Action = [
          "s3:ListBucket"
        ],
        Effect   = "Allow"
        Resource = aws_s3_bucket.web_static_data.arn
        Principal = {
          AWS = [
            local.instance_role_arn
          ]
        },
        Condition = {
          IpAddress = {
            "aws:SourceIp":local.s3.source_ips
          }
        }
      },{
        Sid = "AllowMepsProfileToReadTheBucketObjects"
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.web_static_data.arn}/*"
        Principal = {
          AWS = [
            local.instance_role_arn
          ]
        },
        Condition = {
          IpAddress = {
            "aws:SourceIp": local.s3.source_ips
          }
        }
      }
    ]

  })
}
