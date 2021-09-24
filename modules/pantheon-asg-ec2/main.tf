#--------------------******** IAM ********* ------------------------------------------
resource "aws_iam_role" "asg" {
  name = "${var.name}-${var.enviornment}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow"
        Sid    = "AWAssumeRoleEC2Access"
      }
    ]
  })
}

resource "aws_iam_policy" "asg" {
  name = "${var.name}-${var.enviornment}-ec2-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action = [
          "ec2:GetConsoleOutput",
          "ec2:RunInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeRegions",
          "ec2:DescribeImages",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole",
          "ec2:CreateImage",
          "ec2:CreateSnapshot"
        ]
        Effect   = "Allow"
        Resource = "*"
        Sid      = "SidForEC2ASGOnHDASP"
      }
    ]
  })
}

resource "aws_iam_policy" "s3" {
  name = "${var.name}-${var.enviornment}-playbooks-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Action = [
          "sts:AssumeRole",
        ],
        Effect = "Allow",
        Resource = [aws_iam_role.asg.arn]#["arn:aws:iam::631203585119:role/mepsdev-dev-asg-ec2-role"]
        Sid = "AllowAssumeRole"
      },
      {
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:HeadBucket"
        ],
        Effect = "Allow",
        Resource = ["arn:aws:s3:::hdasp-inventory-playbooks","arn:aws:s3:::hdasp-nexus-repo-artifacts"]
        Sid = "AllowEC2ToAccessPlaybooksAndNexusBuckets"
      },
      {
        Action = [
          "s3:GetObject"
        ],
        Condition = {
          "Bool": {
            "aws:SecureTransport": "true"
          }
        },
        Effect = "Allow",
        Resource = [
          "arn:aws:s3:::hdasp-inventory-playbooks/*","arn:aws:s3:::hdasp-nexus-repo-artifacts/*"
        ],
        Sid = "AllowEC2ToGetOrPutObjectsFromPlaybooksAndNexus"
      }
    ]
  })
  depends_on = [aws_iam_role.asg]
}

resource "aws_iam_role_policy_attachment" "asg" {
  policy_arn = aws_iam_policy.asg.arn
  role       = aws_iam_role.asg.name
}

resource "aws_iam_role_policy_attachment" "s3" {
  policy_arn = aws_iam_policy.s3.arn
  role       = aws_iam_role.asg.name
}

resource "aws_iam_role_policy_attachment" "cw" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.asg.name
}


resource "aws_iam_instance_profile" "asg" {
  name = "${var.name}-${var.enviornment}"
  role = aws_iam_role.asg.name
}

#--------------------******** ************* ------------------------------------------

#-------------------- Security Groups       ------------------------------------------
resource "aws_security_group" "webserver_sg" {
  name   = "${var.name}-${var.enviornment}-ws-access-sg"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = []
}

resource "aws_security_group_rule" "webserver_sg_rule" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  self              = "true"
  security_group_id = aws_security_group.webserver_sg.id
}

resource "aws_security_group_rule" "webserver_vpn_sg_rule" {
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  type                     = "ingress"
  security_group_id        = aws_security_group.webserver_sg.id
  source_security_group_id = var.vpn_security_group_id
}

#Add to RDS Stage Security Group
resource "aws_security_group_rule" "webserver_rds_rule" {
  type                     = "ingress"
  from_port                = 1521
  to_port                  = 1521
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.webserver_sg.id
  description              = "RDS access for webserver"
  security_group_id        = var.database_security_group_id
}

#--------------------******** ************* ------------------------------------------

#-------------------- Launch Template ------------------------------------------
resource "aws_launch_template" "asg" {
  name          = "${var.name}-${var.enviornment}"
  image_id      = var.launch_template.image_id
  instance_type = var.launch_template.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.asg.name
  }
  vpc_security_group_ids  = [aws_security_group.webserver_sg.id]
  disable_api_termination = var.launch_template.disable_instance_termination
  ebs_optimized           = var.launch_template.ebs_optimized
  key_name                = var.launch_template.key_name
  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.name}-${var.enviornment}"
    }
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.launch_template.root_volume_size
      delete_on_termination = true
      volume_type           = "gp2"
      encrypted             = true
    }
  }
  block_device_mappings {
    device_name = "/dev/sdh"
    ebs {
      volume_size           = var.launch_template.attached_volume_size
      delete_on_termination = true
      volume_type           = "gp2"
      encrypted             = true
    }
  }

  depends_on = [aws_security_group.webserver_sg]
}

#--------------------******** ************* ------------------------------------------

#-------------------------AutoScaling Group ------------------------------------------

#asg with launch template
resource "aws_autoscaling_group" "asg_with_lt" {

  desired_capacity          = 1
  max_size                  = 2
  min_size                  = 1
  name                      = "${var.name}-${var.enviornment}"
  health_check_grace_period = 60
  health_check_type         = "EC2"
  force_delete              = true
  launch_template {
    id      = aws_launch_template.asg.id
    version = aws_launch_template.asg.latest_version
  }

  lifecycle {
    create_before_destroy = true
  }
  enabled_metrics     = []
  vpc_zone_identifier = var.private_subnet_ids


  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.name}-${var.enviornment}"
  }
  target_group_arns = [aws_lb_target_group.asg.arn]

  depends_on = [aws_launch_template.asg, aws_lb_target_group.asg]
}



resource aws_autoscalingplans_scaling_plan "asg" {

  name = "${var.name}-${var.enviornment}"
  application_source {
    tag_filter {
      key = "Name"
      values = [
        "${var.name}-${var.enviornment}"
      ]
    }
  }

  scaling_instruction {
    disable_dynamic_scaling = false
    max_capacity            = 2
    min_capacity            = 1

    resource_id                    = format("autoScalingGroup/%s", aws_autoscaling_group.asg_with_lt.name)
    scalable_dimension             = "autoscaling:autoScalingGroup:DesiredCapacity"
    scaling_policy_update_behavior = "KeepExternalPolicies"
    service_namespace              = "autoscaling"
    target_tracking_configuration {
      disable_scale_in          = false
      estimated_instance_warmup = 300
      scale_in_cooldown         = 0
      scale_out_cooldown        = 0
      target_value              = 50

      predefined_scaling_metric_specification {
        predefined_scaling_metric_type = "ASGAverageCPUUtilization"
      }
    }
  }
}

#--------------------******** ************* ------------------------------------------
resource "aws_lb_target_group" "asg" {
  name        = "${var.name}-${var.enviornment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
}

#------------ PARAMETER STORE -----------
resource "aws_ssm_parameter" "instance_profile_name" {
  name = "${var.name}-${var.enviornment}-instance-profile-name"
  type = "String"
  value = aws_iam_instance_profile.asg.name
  overwrite = true
}

resource "aws_ssm_parameter" "instance_name" {
  name = "${var.name}-${var.enviornment}-instance-name"
  type = "String"
  value = aws_iam_instance_profile.asg.name
  overwrite = true
}

resource "aws_ssm_parameter" "asg_name" {
  name = "${var.name}-${var.enviornment}-asg-name"
  type = "String"
  value = aws_autoscaling_group.asg_with_lt.name
  overwrite = true
}

resource "aws_ssm_parameter" "security_group_name" {
  name = "${var.name}-${var.enviornment}-security-group-name"
  type = "String"
  value = aws_security_group.webserver_sg.name
  overwrite = true
}
resource "aws_ssm_parameter" "launch_template_name" {
  name = "${var.name}-${var.enviornment}-launch-template-name"
  type = "String"
  value = aws_launch_template.asg.name
  overwrite = true
}

resource "aws_ssm_parameter" "cicd_slave_ip" {
  count = (var.cicd_private_ip != null ) ? 1 : 0

  name = "${var.name}-${var.enviornment}-private-ip"
  type = "String"
  value = var.cicd_private_ip
  overwrite = true
}

resource "aws_ssm_parameter" "cicd_slave_subnet" {

  count = (var.cicd_subnet_id != null ) ? 1 : 0

  name = "${var.name}-${var.enviornment}-subnet-id"
  type = "String"
  value = var.cicd_subnet_id
  overwrite = true
}