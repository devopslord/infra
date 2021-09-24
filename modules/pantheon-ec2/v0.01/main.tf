resource "aws_security_group" "main" {
  count = (var.ec2_security_group_id != "") ? 0 : 1

  name   = var.name
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project
    Location    = var.region
  }
}

resource "aws_security_group_rule" "main_inbound" {
  count = (var.ec2_security_group_id != "") ? 0 : 1

  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  self              = "true"
  security_group_id = aws_security_group.main[0].id
}

resource "aws_security_group_rule" "vpn" {
  count = (var.ec2_security_group_id != "") ? 0 : 1

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = var.vpn_security_group_id
  security_group_id        = aws_security_group.main[0].id
}

resource "aws_instance" "main" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  iam_instance_profile        = var.instance_profile_name
  key_name                    = var.ec2_key_name
  subnet_id                   = var.subnet_id
  disable_api_termination     = var.disable_api_termination
  private_ip                  = var.override_private_ip
  associate_public_ip_address = var.associate_public_ip
  user_data = var.ec2_userdata
  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_disk_size
    encrypted   = true
  }

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project
    Location    = var.region
  }
}

resource "aws_network_interface_sg_attachment" "main" {
  security_group_id    = (var.ec2_security_group_id != "") ? var.ec2_security_group_id : aws_security_group.main[0].id
  network_interface_id = aws_instance.main.primary_network_interface_id

  depends_on = [aws_instance.main]
}

resource "aws_network_interface_sg_attachment" "tennable" {
  count = var.allow_tennable_scanner ? 1 : 0

  security_group_id    = var.tennable_scanner_sg_id
  network_interface_id = aws_instance.main.primary_network_interface_id

  depends_on = [aws_instance.main]
}

resource "aws_ebs_volume" "main" {
  count = var.ebs_volume ? 1 : 0

  availability_zone = aws_instance.main.availability_zone
  size              = var.disk_space
  encrypted         = true
  type              = "gp2"

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project
    Location    = var.region
  }
}

resource "aws_volume_attachment" "main" {
  count = var.ebs_volume ? 1 : 0

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.main[count.index].id
  instance_id = aws_instance.main.id
}

resource "aws_cloudwatch_log_group" "main" {
  count = (var.log_group != "")? 1 : 0
  name = var.log_group

  tags = {
    Name        = var.name
    Environment = var.environment
    Project     = var.project
    Location    = var.region
  }
}

resource "aws_cloudwatch_log_stream" "main" {
  count          = length(var.log_stream)

  name           = var.log_stream[count.index]
  log_group_name = var.log_group
}

resource "aws_cloudwatch_log_subscription_filter" "main" {
  count = (var.cloudwatch_log_subscription_filter_role_arn != "") ? 1 : 0

  name            = "${var.name}-cw-to-firehose"
  role_arn        = var.cloudwatch_log_subscription_filter_role_arn
  log_group_name  = aws_cloudwatch_log_group.main[0].name
  filter_pattern  = ""
  destination_arn = var.cloudwatch_log_subscription_filter_destination_arn

}
