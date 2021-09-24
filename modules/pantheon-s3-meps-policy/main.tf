resource "aws_iam_policy" "web_static_data" {
  name        = "${var.policy_name}-s3access-policy"
  path        = var.policy_saved_location
  description = "This policy is to allow MEPS Server Instance Profile Access To S3 bucket for MEPS Static Content purposes."
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid      = "AllowEC2MEPSCLIToMakeSTSCallsOnInstanceRole",
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = var.instance_role_arn
      },
      {
        Sid    = "AllowMEPSEC2ToListBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Sid    = "AllowMEPSEC2ToListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:HeadBucket"
        ]
        Resource = var.s3_bucket_arn
      },
      {
        Sid    = "AllowMEPSEC2ToListBucketObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = ["${var.s3_bucket_arn}/*"]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "true"
          }
        }
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "web_static_data" {
  policy_arn = aws_iam_policy.web_static_data.arn
  role       = var.instance_role_name
}