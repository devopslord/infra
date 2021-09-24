resource "aws_cloudwatch_log_stream" "main" {
  name           = var.name
  log_group_name = var.log_group
}

resource "aws_ec2_client_vpn_endpoint" "main" {
  server_certificate_arn = var.server_cert_arn
  client_cidr_block      = "172.31.0.0/22"
  split_tunnel           = var.split_tunnel

  authentication_options {
    type                       = "certificate-authentication"
    root_certificate_chain_arn = var.client_cert_arn
  }

  connection_log_options {
    enabled               = true
    cloudwatch_log_group  = var.log_group
    cloudwatch_log_stream = var.name
  }

  tags = {
    Name = var.name
  }
}

resource "aws_ec2_client_vpn_network_association" "main" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.main.id
  subnet_id              = var.subnet_id
}

resource "aws_security_group" "main" {
  name   = "${var.name}_vpn"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "main" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  self              = true
  security_group_id = aws_security_group.main.id
}
