# VPC FLow Log
resource "aws_flow_log" "vpc_flow_log" {

  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.cloud_watch.arn
  vpc_id          = var.vpc_id
  #log_format      = var.log_format

  tags = {
    Environment = var.environment
    Name        = var.name
  }
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = var.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect : "Allow",
        Action : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
        ],
        Resource : "*"
      }
    ]
  })
  role = aws_iam_role.vpc_flow_log.id
}
#Passrole
resource "aws_iam_policy" "pass_policy" {
  name = var.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = aws_iam_role.vpc_flow_log.arn
      }
    ]
  })
}

#VPC Flowlog Role (Assume Role)
resource "aws_iam_role" "vpc_flow_log" {
  name = var.name
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "PolicyForVPCFlowLogToAssumeARole"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
  }
}

#Attach Policies and Role to Identities
resource "aws_iam_policy_attachment" "vpc_flow_log" {
  name       = var.name
  policy_arn = aws_iam_policy.pass_policy.arn
  users      = [var.username]
  roles      = [aws_iam_role.vpc_flow_log.name]
}

resource "aws_cloudwatch_log_group" "cloud_watch" {
  name = var.log_group
  tags = {
    Environment = var.environment
    Name        = var.name
  }
}

