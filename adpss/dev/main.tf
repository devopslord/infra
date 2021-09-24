terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "adpss/dev/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

locals {
  instance_role_arn    = "arn:aws:iam::631203585119:role/adpss-dev"
  s3_software_repo_arn = "arn:aws:s3:::hdasp-adpss-repo"
  security_groups = {
    Adpss_Sg_Id = "sg-0acc0821efa1f7bcb"
  }
}

# DEV VPC Data source
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/adpss/dev/terraform.tfstate"
    region = "us-east-1"
  }
}


data "terraform_remote_state" "vpn" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpn/adpss/terraform.tfstate"
    region = "us-east-1"
  }
}
###########
# windows sas dev instance
module "sas" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = var.name
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-00f7dbe1ae53c10f8"#"ami-0c0f07eb13ed17405"
  instance_type           = "t3.medium"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size          = 300
  ebs_volume              = false
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = false
  log_group               = "/adpss/dev"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  override_private_ip                                = "10.39.1.47"
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment

}

data "aws_security_group" "ec2_sg_id" {
  id     = module.sas.security_group_id
  name   = module.sas.security_group_name
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

# windows sastest dev instance
module "sastest" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = var.nametest
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-00f7dbe1ae53c10f8"#"ami-0c0f07eb13ed17405"
  instance_type           = "t3.medium"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size          = 300
  ebs_volume              = false
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = false
  log_group               = "/adpss/dev"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  override_private_ip                                = "10.39.1.48"
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment

}

data "aws_security_group" "ec2_sgtest_id" {
  id     = module.sastest.security_group_id
  name   = module.sastest.security_group_name
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}

/*resource "aws_security_group_rule" "dev_ec2_rdp" {
  from_port                = 3389
  protocol                 = "TCP"
  source_security_group_id = local.security_groups.Adpss_Sg_Id
  security_group_id        = data.aws_security_group.ec2_sg_id.id
  to_port                  = 3389
  type                     = "ingress"
}*/

#enables vpc flow log on dev
/*module "vpc-flow-log" {
  source      = "../../modules/pantheon-vpc-flowlog"
  log_group   = "adpss/vpc/dev"
  log_format  = var.log_format
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  name        = "${var.name}-flowlog"
  environment = var.environment
  username    = "aschadalavada@panth.com"
}*/

#create vpc endpoint for cloudwatch logs
/*
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [var.adpss_dev_sg_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true
  tags = {
    Name        = var.name
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "metrics" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.monitoring"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true
  tags = {
    Name        = var.name
    Environment = var.environment
  }
}*/

# create cloudwatch alarms for metrics - diskspace and memory utilization
## Precursor make sure cloudwatch agent is installed, configured and running on each instance
/*
variable "alarmname" {
  description = "Define the alarm name to capture disk free metric"
}
resource "aws_cloudwatch_metric_alarm" "diskspace_metric_alarm" {
  alarm_name = var.alarmname
  namespace = "CWAgent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  threshold = 90
  metric_name = "PhysicalDisk % Disk Time"
  alarm_description = "Alarm to monitor % of disk free space"

}


#sns resource
resource "aws_sns_topic" "sns" {
  name = var.name

  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = var.name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "sns" {
  endpoint = ""
  protocol = "sns"
  topic_arn = aws_sns_topic.sns.arn

  depends_on = [aws_sns_topic.sns]
}
#----Cloudwatch Alarm metric for disk and memory stats
resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name = var.alarmname
  comparison_operator = ""
  evaluation_periods = 0
  threshold = 0
}*/


//create policy ssm
//attach policy to existing instance role
//create vpc endpoint for ssm for security posture.
/*
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true
  tags = {
    Name        = "${var.name}-ssm"
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}
resource "aws_vpc_endpoint" "ssm_ec2messages" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true
  tags = {
    Name        = "${var.name}-ec2messages"
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}
resource "aws_vpc_endpoint" "ssm_ec2" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true
  tags = {
    Name        = "${var.name}-ec2"
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = module.sas.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
resource "aws_s3_bucket" "ssm" {
  bucket = "hdasp-inventory-playbooks-${var.name}"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = {
    Name        = "${var.name}-ssm"
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}
resource "aws_s3_bucket_public_access_block" "ssm" {
  bucket              = aws_s3_bucket.ssm.id
  block_public_acls   = true
  block_public_policy = true
}
resource "aws_s3_bucket_policy" "ssm" {
  bucket = aws_s3_bucket.ssm.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowingAllActionsForTheAccount",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::631203585119:root"
        },
        Action   = "s3:*",
        Resource = "${aws_s3_bucket.ssm.arn}/*"
        }, {
        Sid    = "AllowReadForSSM",
        Effect = "Allow",
        Principal = {
          Service = ["ssm.amazonaws.com"]
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.ssm.arn}/*"
      }
    ]
  })
}
resource "aws_iam_policy" "ssm" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowEC2RoleToAccessS3PlaybooksBucket",
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = [aws_s3_bucket.ssm.arn, "${aws_s3_bucket.ssm.arn}/*"]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  policy_arn = aws_iam_policy.ssm.arn
  role       = var.name
}
*/
# creating windows media files volume from aws managed snapshot
/* removed as it is no longer needed */
/*resource "aws_ebs_volume" "win_media" {
  availability_zone = module.sas.availability_zone
  size = 10
  snapshot_id = "snap-22da283e"
  type = "gp2"
  tags = {
    Name        = "${var.name}-win-media"
    Environment = var.environment
  }

}

resource "aws_volume_attachment" "main" {
  device_name = "xvdw"
  volume_id   = aws_ebs_volume.win_media.id
  instance_id = module.sas.instance_id
}*/


#WINDOWS Server 2016 Installation Media
resource "aws_ebs_volume" "windows_updates" {
  availability_zone = "us-east-1d"
  size              = "30"
  encrypted         = true
  type              = "gp2"
  snapshot_id       = "snap-22da283e"
  tags = {
    Name        = var.name
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}

/*
resource "aws_volume_attachment" "windows_updates" {
  device_name = "xvdw"
  volume_id   = aws_ebs_volume.windows_updates.id
  instance_id = module.sas.instance_id
}*/

#DELETE BELOW CODE
/*module "adass_cis_new_ec2" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = "adass-new"
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-0d2f75f783456a1cc"
  instance_type           = "t3.medium"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size          = 300
  ebs_volume              = false
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = false
  log_group               = "/adass/dev"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  override_private_ip                                = "10.39.1.48"
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment

}*/
