Steps:

1. Enable Guard Duty service
2. Create Cloudwatch event rules
3. Create Cloudwatch alarms

```html
/*resource "aws_s3_bucket" "main" {
  bucket        = var.cloudtrailname
  force_destroy = false
  acl           = "private"
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid    = "HDASPCloudTrailACLChecks",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "S3:GetBucketAcl",
        Resource = aws_s3_bucket.main.arn
      },
      {
        Sid    = "HDASPCloudTrailWriteLog",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.main.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}*//*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}*/
```