terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "global/config/terraform.tfstate"
    region = "us-east-1"
  }
}
#--- configure cloudwatch events and metrics for enabled guardduty service
resource "aws_cloudwatch_event_rule" "main" {
  name = "${var.awsconfig_name}_event_rules"
  event_pattern = jsonencode({
    "source": [
      "aws.config"
    ],
    "detail-type": [
      "Config Rules Compliance Change"
    ],
    "detail": {
      "messageType": [
        "ComplianceChangeNotification"
      ],
      "newEvaluationResult": {
        "complianceType": ["NON_COMPLIANT"]
      }
    }
  })
  description = "HDASP Account Config Compliance Change Event"

  tags = {
    Name = "hdasp"
  }
}

resource "aws_cloudwatch_event_target" "main" {
  rule = aws_cloudwatch_event_rule.main.name
  arn = var.sns_arn
}

resource "aws_cloudwatch_metric_alarm" "main" {
  namespace = "ADPSS"
  alarm_name = "cw_failed_event_rules"
  alarm_description = "Cloudwatch rules not delivering events to respective targets"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = 5
  threshold = 10
  statistic = "Sum"
  period = 60
  metric_name = "FailedInvocations"
  alarm_actions = [var.sns_arn]

}