terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "global/guardduty/terraform.tfstate"
    region = "us-east-1"
  }
}
#--- configure cloudwatch events and metrics for enabled guardduty service
resource "aws_cloudwatch_event_rule" "main" {
  name = "${var.guardduty_name}_event_rules"
  event_pattern = jsonencode({
    "source" : [
      "aws.guardduty"
    ],
    "detail-type" : [
      "GuardDuty Finding",
      "EC2/TrafficVolumeUnusual",
      "EC2/DGADomainRequest.B",
      "UnauthorizedAccess:EC2/TorIPCaller"
    ],
    "detail" : [
      7.0, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8, 8.0, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9
    ],
    "resources" : [
      "arn:aws:ec2:us-east-1:631203585119:instance/i-0678ebe4363e0dd66",
      "arn:aws:ec2:us-east-1:631203585119:instance/i-0d68c18768eb377e9"
    ]
  })
  description = "HDASP Account Guardduty Findings"

  tags = {
    Name = "hdasp"
  }
}

resource "aws_cloudwatch_event_target" "main" {
  rule = aws_cloudwatch_event_rule.main.name
  arn  = "arn:aws:sns:us-east-1:631203585119:hdasp-security"

  input_transformer {
    input_paths = {
      "Finding_ID"          = "$.detail.id"
      "Finding_Type"        = "$.detail.type"
      "Finding_description" = "$.detail.description"
      "count"               = "$.detail.service.count"
      "eventFirstSeen"      = "$.detail.service.eventFirstSeen"
      "eventLastSeen"       = "$.detail.service.eventLastSeen"
      "instanceId"          = "$.detail.resource.instanceDetails.instanceId"
      "port"                = "$.detail.service.action.networkConnectionAction.localPortDetails.port"
      "region"              = "$.region"
      "severity"            = "$.detail.severity"

    }
    input_template = "\"You have a severity <severity> GuardDuty finding type <Finding_Type> for the EC2 instance <instanceId> in the region <region> as the <Finding_description> on the port <port>. The first attempt was on <eventFirstSeen> and the most recent attempt on <eventLastSeen> . The total occurrence is <count>. For more details open the GuardDuty console at https://console.aws.amazon.com/guardduty/home?region=<region>#/findings?search=id%3D<Finding_ID>\""
  }
}

resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  tags                         = {
    Name = "hdasp"
  }
}