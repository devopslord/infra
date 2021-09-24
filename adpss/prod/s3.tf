# create s3 bucket to host all libraries, patches, etc needed to install on ADPSS Server
# Requires bucket policy allowing access to only ADPSS server
module "s3_bucket_repo" {
  source      = "../../modules/pantheon-s3-bucket"
  bucket_name = "hdasp-adpss-repo"
}

resource "aws_s3_bucket_policy" "s3_bucket_repo" {
  bucket = module.s3_bucket_repo.bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowRoleToReadTheBucket"
        Action = [
          "s3:ListBucket"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${module.s3_bucket_repo.bucket_arn}"
        Principal = {
          AWS = [
            "arn:aws:iam::631203585119:role/adpss"
          ]
        },
        Condition = {
          IpAddress = {
            "aws:SourceIp" : local.adpss_ip
          }
        }
        }, {
        Sid = "AllowMepsProfileToReadTheBucketObjects"
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::${module.s3_bucket_repo.bucket_arn}/*"
        Principal = {
          AWS = [
            local.instance_role_arn
          ]
        },
        Condition = {
          IpAddress = {
            "aws:SourceIp" : local.adpss_ip
          }
        }
      }
    ]

  })
}

/*
S3 Data Lifecycle For Copying and Storing Large Volumes of Data (H, M, P, R, O Drives)
FOR DATA ARCHIVAL PURPOSES
*/

resource "aws_iam_policy" "data" {
  name        = "${var.name}-s3access-policy"
  path        = "/adpss/"
  description = "This policy is to allow ADPSS Server Instance Profile Access To S3 bucket for archival and software repository bucket purposes."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid      = "AllowEC2AdpssCLIToMakeSTSCallsOnInstanceRole",
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = "arn:aws:iam::631203585119:role/adpss"
      },
      {
        Sid    = "AllowAdpssEC2ToListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [aws_s3_bucket.data.arn, local.s3_software_repo_arn]
      },
      {
        Sid    = "AllowAdpssEC2ToListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:HeadBucket"
        ]
        Resource = [aws_s3_bucket.data.arn, local.s3_software_repo_arn]
      },
      {
        Sid    = "AllowAdpssEC2ToListBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = ["${aws_s3_bucket.data.arn}/*", "${local.s3_software_repo_arn}/*"]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "data" {
  policy_arn = aws_iam_policy.data.arn
  role       = "adpss"
}

resource "aws_s3_bucket" "data" {
  bucket = "hdasp-adpss-archive"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        #using the same algorithm as with EBS Volumes
        sse_algorithm = "AES256"
      }
    }
  }
  acceleration_status = "Enabled"
  acl                 = "private"
  force_destroy       = false
  tags                = merge(local.common_tags, map("Name", "${var.name}-metrics"))

  lifecycle_rule {
    id                                     = "to-deep-archive"
    abort_incomplete_multipart_upload_days = 7
    enabled                                = true
    tags                                   = {}
    expiration {
      days                         = 0
      expired_object_delete_marker = true
    }
    transition {
      storage_class = "DEEP_ARCHIVE"
      days          = 1
    }

  }
  logging {
    target_bucket = "hdasp-inventory"
    target_prefix = "s3/data/adpss-s3-archive-"
  }
}

resource "aws_s3_bucket_public_access_block" "data" {
  bucket = aws_s3_bucket.data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "s3" {
  bucket = aws_s3_bucket.data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowAdpssProfileToReadTheBucket"
        Action = [
          "s3:ListBucket"
        ],
        Effect   = "Allow"
        Resource = "arn:aws:s3:::hdasp-adpss-archive"
        Principal = {
          AWS = [
            "arn:aws:iam::631203585119:role/adpss"
          ]
        },
        Condition = {
          IpAddress = {
            "aws:SourceIp" = local.adpss_ip
          }
        }
      },
      {
        Sid = "AllowAdpssProfileToCRUDTheBucketObjects"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:s3:::hdasp-adpss-archive/*",
        Principal = {
          AWS = [
            "arn:aws:iam::631203585119:role/adpss"
          ]
        },
        Condition = {
          IpAddress = {
            "aws:SourceIp" = local.adpss_ip
          }
        }
      }
    ]

  })
}

resource "aws_s3_bucket_notification" "sns" {
  bucket = aws_s3_bucket.data.id
  topic {
    events = [
      "s3:ObjectRestore:Completed",
      "s3:ObjectRestore:Post",
      "s3:Replication:OperationFailedReplication",
    ]
    filter_prefix = "archive"
    id            = "AdpssRestoreNotifications"
    topic_arn     = "arn:aws:sns:us-east-1:631203585119:hdasp-security" #aws_sns_topic.sns.arn
  }
}