terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/new-relic-aws/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

resource "aws_iam_role" "main" {
  name = "new_relic"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::754728514883:root"
        },
        Effect = "Allow"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "2650984"
          }
        }
      }
    ]
  })
}

data "aws_iam_policy" "main" {
  arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_policy" "budget" {
  name = "NewRelicBudget"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "budgets:ViewBudget"
        ],
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = data.aws_iam_policy.main.arn
}

resource "aws_iam_role_policy_attachment" "budget" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.budget.arn
}
