#-------------------------------------Private Connection Endpoints -------------------------------------
# vpc endpoints for logging and monitoring from within private subnets with no ingress/egress public traffic
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-logs"))
}

resource "aws_vpc_endpoint" "metrics" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.monitoring"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-metrics"))
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  auto_accept       = true

  tags = merge(local.common_tags, map("Name", "${var.name}-s3"))
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.sts"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-sts"))
}

//add nacl
resource "aws_network_acl_rule" "s3" {
  count          = length(aws_vpc_endpoint.s3.cidr_blocks)
  network_acl_id = "acl-0ca8eb73a8d8d3719"
  rule_number    = 6 + count.index
  egress         = true

  protocol    = "tcp"
  from_port   = "443"
  to_port     = "443"
  rule_action = "allow"
  cidr_block  = aws_vpc_endpoint.s3.cidr_blocks[count.index]
}
//add to sg

#-------------------------------------Metrics, Alarms CW-------------------------------------
#cloudwatch alarm metrics
resource "aws_cloudwatch_metric_alarm" "diskspace_metric_alarm" {
  count               = length(var.disk_drives)
  namespace           = upper(var.name)
  alarm_name          = "${var.name}-sas-${var.disk_drives[count.index]}-disk"
  alarm_description   = "Alarm to monitor % of disk free space"
  alarm_actions       = [aws_sns_topic.sns.arn]
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 6
  threshold           = 5
  metric_name         = "LogicalDisk % Free Space"
  treat_missing_data  = "missing"
  datapoints_to_alarm = 3
  statistic           = "Average"
  period              = "300"
  dimensions = {
    host       = var.hostname
    instance   = var.disk_drives[count.index]
    objectname = "LogicalDisk"
  }
  tags       = merge(local.common_tags, map("Name", var.name))
  depends_on = [aws_sns_topic.sns]
}

resource "aws_cloudwatch_metric_alarm" "memory_metric_alarm" {
  namespace           = upper(var.name)
  alarm_name          = "${var.name}-sas-memory"
  alarm_description   = "Alarm to monitor Memory % In Use"
  alarm_actions       = [aws_sns_topic.sns.arn]
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 6
  threshold           = 90
  metric_name         = "Memory % Committed Bytes In Use"
  treat_missing_data  = "missing"
  datapoints_to_alarm = 3
  statistic           = "Average"
  period              = "300"
  dimensions = {
    host       = var.hostname
    objectname = "Memory"
  }
  tags       = merge(local.common_tags, map("Name", var.name))
  depends_on = [aws_sns_topic.sns]
}

#-------------------------------------SNS Notification-------------------------------------
#sns topic resource
resource "aws_sns_topic" "sns" {
  name         = "${var.name}-mon"
  display_name = "${var.name}-mon"

  lifecycle {
    prevent_destroy = true
  }
  tags = merge(local.common_tags, map("Name", var.name))
}
#sns email topic subscription using local-exec. Note: Since Terraform doesn't inherently support email subscription had to avail loal-exec.
resource "null_resource" "null_id" {
  count = length(var.subscribers)
  provisioner "local-exec" {
    command = "aws sns subscribe --topic-arn ${aws_sns_topic.sns.arn} --protocol email --notification-endpoint ${var.subscribers[count.index]}"
  }
}