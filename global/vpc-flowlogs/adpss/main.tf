terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/vpc-flowlogs/adpss/terraform.tfstate"
    region  = "us-east-1"
  }
}

# aws_iam_role.main:
resource "aws_iam_role" "main" {
  assume_role_policy    = jsonencode(
  {
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Sid       = "ADPSSVPCFlowLogTrustPolicy"
      },
    ]
    Version   = "2012-10-17"
  }
  )
  description           = "Allows to capture vpc flowlogs of adpss vpc"
  force_detach_policies = false
  max_session_duration  = 3600
  name                  = "adpss-vpc-flowlog-role"
  path                  = "/"
  tags                  = {
    "Name" = "adpss"
  }
}


resource "aws_iam_policy" "main" {
  description = "This policy is to allow ADPSS VPCflowlogs to access cloudwatch logs"
  name        = "adpss-vpc-flowlog-to-cloudwatch-policy"
  path        = "/"
  policy      = jsonencode(
  {
    Statement = [
      {
        Action   = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
    Version   = "2012-10-17"
  }
  )
}

resource "aws_iam_role_policy_attachment" "main" {
  policy_arn = aws_iam_policy.main.arn
  role = aws_iam_role.main.name
}


# aws_flow_log.main:
resource "aws_flow_log" "main" {
  iam_role_arn             = aws_iam_role.main.arn
  log_destination          = var.cw_log_destination_arn
  log_destination_type     = "cloud-watch-logs"
  log_format               = var.log_format
  max_aggregation_interval = 600
  tags                     = {
    "Name" = "adpss"
  }
  traffic_type             = "ALL"
  vpc_id                   = var.vpc_id
}
