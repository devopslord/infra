terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "meps/asg/iam/terraform.tfstate"
    region = "us-east-1"
  }
}

#Manage IAM Policies for SSM on CICD Instace profile to access SSM and S3 Objects (playbooks)

resource "aws_iam_policy" "asg" {
  name = "${var.jenkins_master_instance_profile}-asg-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = ["arn:aws:s3:::hdasp-nexus-repo-artifacts"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = ["arn:aws:s3:::hdasp-nexus-repo-artifacts/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
        ]
        Resource = "*"
      },
/*      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
        ]
        Resource = "arn:aws:ec2:*:*:instance*//*"
        Condition = {
          StringLike = {
            "ssm:ResourceTag/Name" : ["hdasp-jenkins"]
          }
        }
      },*/
      {
        Effect = "Allow"
        Action = [
          "ec2:GetConsoleOutput",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",

          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "iam:ListInstanceProfilesForRole",
          "ec2:CreateImage",
          "ec2:DeregisterImage",
          "ec2:DescribeImages",
          "iam:PassRole"
        ]
        Resource = "*"
        Sid      = "SidForJenkinsOnHDASP"
        Condition = {
          StringLike = {
            "aws:ResourceTag/Name" : ["hdasp-jenkins"]
          }
        }
        }, {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "ds:CreateComputer",
          "ds:DescribeDirectories",
          "ec2:DescribeInstanceStatus",
          "logs:*",
          "ssm:*",
          "ec2messages:*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/Name" : ["hdasp-jenkins"]
          }
        }
        }, {
        Effect = "Allow"
        Action = [
          "iam:CreateServiceLinkedRole"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*"
        Condition = {
          StringLike = {
            "iam:AWSServiceName" : "ssm.amazonaws.com"
          }
        }
        }, {
        Effect = "Allow"
        Action = [
          "iam:DeleteServiceLinkedRole",
          "iam:GetServiceLinkedRoleDeletionStatus"
        ]
        Resource = "arn:aws:iam::*:role/aws-service-role/ssm.amazonaws.com/AWSServiceRoleForAmazonSSM*"
        }, {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Resource = "*"
      },
      {
        Action = [
          "s3:ListBucket"
        ],
        Condition : {
          Bool = {
            "aws:SecureTransport" : "true"
          }
        }
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::hdasp-inventory-playbooks"
        ],
        Sid : "AllowHDASPS3PlaybookBucket"
        }, {
        Action = [
          "s3:GetObject"
        ],
        Condition : {
          Bool = {
            "aws:SecureTransport" : "true"
          }
        }
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::hdasp-inventory-playbooks/*"
        ],
        Sid : "AllowReadAccessToPlaybooksInTheBucket"
      }
    ]
  })
}

resource "aws_iam_policy" "asg_s3_access" {
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = ["arn:aws:s3:::hdasp-nexus-repo-artifacts"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:GetObjectAcl",
          "s3:DeleteObject"
        ]
        Resource = ["arn:aws:s3:::hdasp-nexus-repo-artifacts/*"]
      }
      ]
  })
}

/*resource "aws_iam_role_policy_attachment" "asg1" {
  policy_arn = aws_iam_policy.asg.arn
  role       = var.jenkins_master_instance_profile
  depends_on = [aws_iam_policy.asg]
}*/

resource "aws_iam_role_policy_attachment" "asg-s3-access" {
  policy_arn = aws_iam_policy.asg.arn
  role       = var.jenkins_master_instance_profile
  depends_on = [aws_iam_policy.asg_s3_access]
}

resource "aws_iam_role_policy_attachment" "asg-ec2-ssm-access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"#"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role = var.jenkins_master_instance_profile
  depends_on = [aws_iam_policy.asg_s3_access]
}

resource "aws_iam_policy" "jenkins" {
  name = "${var.jenkins_master_instance_profile}-cicd-permissions-for-jenkins-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action = [
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:CreateImage",
          "ec2:DeregisterImage"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "SidForASGPermissionsForJenkinsOnHDASP"
      }
    ]

  })
}


resource "aws_iam_role_policy_attachment" "jenkins" {
  policy_arn = aws_iam_policy.jenkins.arn
  role       = var.jenkins_master_instance_profile
}
