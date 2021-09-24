terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "global/cloudtrail/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "main" {
  cloud_watch_logs_group_arn    = aws_cloudwatch_log_group.main.arn # "arn:aws:logs:us-east-1:631203585119:log-group:/hdasp/cloudtrail/:*"
  cloud_watch_logs_role_arn     = "arn:aws:iam::631203585119:role/hdasp-cloudtrail_role"
  enable_log_file_validation    = true
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = false
  name                          = var.cloudtrailname
  s3_bucket_name                = "hdasp-inventory"
  s3_key_prefix                 = "Cloudtrail"
  #sns_topic_name                = "arn:aws:sns:us-east-1:631203585119:outcomestopic"
  tags = {
    "Name" = "hdasp"
  }
}




#------ CW -----------
#arn:aws:iam::631203585119:role/hdasp-cloudtrail_role
resource "aws_iam_role" "main" {
  name = "${var.cloudtrailname}_role"
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "cloudtrail.amazonaws.com"
          }
          Sid = "HDASPCloudTrailToAssumeRole"
        },
      ]
      Version = "2012-10-17"
    }
  )
  force_detach_policies = false

  tags = {
    Name = var.cloudtrailname
  }

}


resource "aws_iam_policy" "main" {
  name = "${var.cloudtrailname}_policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid    = "AWSCloudTrailCreateLogStream",
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream"
        ],
        Resource = [
          "arn:aws:logs:us-east-1:631203585119:log-group:/hdasp/cloudtrail/:log-stream:631203585119_CloudTrail_us-east-1*"
        ]
      },
      {
        Sid    = "AWSCloudTrailPutLogEvents",
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:us-east-1:631203585119:log-group:/hdasp/cloudtrail/:log-stream:631203585119_CloudTrail_us-east-1*"
        ]
      }
    ]

  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}



/*
{
"Version": "2012-10-17",
"Statement": [
{
"Sid": "AWSCloudTrailCreateLogStream20141101",
"Effect": "Allow",
"Action": [
"logs:CreateLogStream"
],
"Resource": [
"arn:aws:logs:us-east-1:631203585119:log-group:/hdasp/cloudtrail/:log-stream:631203585119_CloudTrail_us-east-1*"
]
},
{
"Sid": "AWSCloudTrailPutLogEvents20141101",
"Effect": "Allow",
"Action": [
"logs:PutLogEvents"
],
"Resource": [
"arn:aws:logs:us-east-1:631203585119:log-group:/hdasp/cloudtrail/:log-stream:631203585119_CloudTrail_us-east-1*"
]
}
]
}*/
resource "aws_cloudwatch_log_group" "main" {
  name = var.cloudtrail_loggroup_name
}