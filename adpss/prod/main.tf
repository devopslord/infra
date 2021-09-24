terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "adpss/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

locals {
  common_tags = {
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }

  security_groups = {
    Tennable_Scanner_Sg_Id = "sg-0790a489a861e5418"
    Adpss_Sg_Id            = "sg-0acc0821efa1f7bcb"
  }
  //adpss_ip             = "10.38.1.63"
  adpss_ip             = "10.38.1.60"
  instance_role_arn    = "arn:aws:iam::631203585119:role/adpss"
  s3_software_repo_arn = "arn:aws:s3:::hdasp-adpss-repo"
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/adpss/terraform.tfstate"
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

module "sas" {
  source                  = "../../modules/pantheon-ec2/"
  name                    = var.name
  vpc_id                  = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                  = "ami-00f7dbe1ae53c10f8" # CIS Microsoft Windows Server 2016 Base
  instance_type           = "i3.16xlarge"
  ec2_key_name            = "pantheon"
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size          = 300
  ebs_volume              = false
  disable_api_termination = true
  vpn_security_group_id   = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner  = true
  tennable_scanner_sg_id  = local.security_groups.Tennable_Scanner_Sg_Id
  log_group               = "/adpss"
  log_stream = [
    "C/WINDOWS/system32/config/COMPONENTS",
    "C/WINDOWS/system32/config/SECURITY",
    "C/WINDOWS/system32/config/SOFTWARE",
    "C/WINDOWS/system32/config/SYSTEM"
  ]
  cloudwatch_log_subscription_filter_role_arn        = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_role_arn
  cloudwatch_log_subscription_filter_destination_arn = data.terraform_remote_state.vpc.outputs.cloudwatch_log_subscription_filter_destination_arn
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment
}

/*
module "sas_nu" {
  source                                             = "../../modules/pantheon-ec2/v0.01/"
  name                                               = "${var.name}-8x"
  vpc_id                                             = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                                             = "ami-09c1e787f08e288cf" # CIS Microsoft Windows Server 2016 Base
  instance_type                                      = "i3.8xlarge"
  ec2_key_name                                       = "pantheon"
  subnet_id                                          = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size                                     = 300
  ebs_volume                                         = false
  disable_api_termination                            = true
  vpn_security_group_id                              = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner                             = true
  tennable_scanner_sg_id                             = local.security_groups.Tennable_Scanner_Sg_Id
  log_group                                          = "" #already exists
  log_stream                                         = []
  cloudwatch_log_subscription_filter_role_arn        = "" #already exists
  cloudwatch_log_subscription_filter_destination_arn = "" #already exists
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment
  instance_profile_name                              = var.name
  ec2_security_group_id                              = local.security_groups.Adpss_Sg_Id
  ec2_userdata                                       = <<EOF
      <powershell>
      $PhysicalDisks = Get-PhysicalDisk -CanPool $True
      if ($PhysicalDisks -ne $null) {
          New-Storagepool -FriendlyName "SasTempData" -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $PhysicalDisks
          #Get-VirtualDisk -StoragePool (Get-StoragePool -FriendlyName "SasTempData")
          New-VirtualDisk -FriendlyName "SasTempData" -StoragePoolFriendlyName SasTempData -UseMaximumSize -ResiliencySettingName Simple -ProvisioningType Fixed
          Get-Disk | Where-Object OperationalStatus -eq 'Offline' |Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem NTFS -DriveLetter D -FriendlyName 'Local System'
          Write-EventLog -LogName Application -Source "Desktop Window Manager" -EventID 9997 -EntryType Information -Message "Completed Mounting SasTempData D Drive"  -Category 1 -RawData 10,20
      } else {
          Write-EventLog -LogName Application -Source "Desktop Window Manager" -EventID 9997 -EntryType Information -Message "No disks found to create pool. Check the disks in disk management."  -Category 1 -RawData 10,20
      }
    </powershell>
    <persist>true</persist>
  EOF
}
*/

module "sas_aug20" {
  source                                             = "../../modules/pantheon-ec2/v0.01/"
  name                                               = "${var.name}-sas-aug20"
  vpc_id                                             = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                                             = "ami-04f1464194a363682" # CIS Microsoft Windows Server 2016 Base
  instance_type                                      = "i3.16xlarge"
  ec2_key_name                                       = "pantheon"
  subnet_id                                          = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size                                     = 400
  ebs_volume                                         = false
  disable_api_termination                            = true
  vpn_security_group_id                              = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner                             = true
  tennable_scanner_sg_id                             = local.security_groups.Tennable_Scanner_Sg_Id
  log_group                                          = "" #already exists
  log_stream                                         = []
  cloudwatch_log_subscription_filter_role_arn        = "" #already exists
  cloudwatch_log_subscription_filter_destination_arn = "" #already exists
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment
  instance_profile_name                              = var.name
  ec2_security_group_id                              = local.security_groups.Adpss_Sg_Id
  ec2_userdata                                       = <<EOF
      <powershell>
      $PhysicalDisks = Get-PhysicalDisk -CanPool $True
      if ($PhysicalDisks -ne $null) {
          New-Storagepool -FriendlyName "SasTempData" -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $PhysicalDisks
          #Get-VirtualDisk -StoragePool (Get-StoragePool -FriendlyName "SasTempData")
          New-VirtualDisk -FriendlyName "SasTempData" -StoragePoolFriendlyName SasTempData -UseMaximumSize -ResiliencySettingName Simple -ProvisioningType Fixed
          Get-Disk | Where-Object OperationalStatus -eq 'Offline' |Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem NTFS -DriveLetter D -FriendlyName 'Local System'
          Write-EventLog -LogName Application -Source "Desktop Window Manager" -EventID 9997 -EntryType Information -Message "Completed Mounting SasTempData D Drive"  -Category 1 -RawData 10,20
      } else {
          Write-EventLog -LogName Application -Source "Desktop Window Manager" -EventID 9997 -EntryType Information -Message "No disks found to create pool. Check the disks in disk management."  -Category 1 -RawData 10,20
      }
    </powershell>
    <persist>true</persist>
  EOF
}


module "sas_test_a20" {
  source                                             = "../../modules/pantheon-ec2/v0.01/"
  name                                               = "${var.name}-sas-test-a20"
  vpc_id                                             = data.terraform_remote_state.vpc.outputs.vpc_id
  ami_id                                             = "ami-04f1464194a363682" # CIS Microsoft Windows Server 2016 Base
  instance_type                                      = "t3.medium"
  ec2_key_name                                       = "pantheon"
  subnet_id                                          = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  root_disk_size                                     = 300
  ebs_volume                                         = false
  disable_api_termination                            = true
  vpn_security_group_id                              = data.terraform_remote_state.vpn.outputs.vpn_security_group_id
  allow_tennable_scanner                             = true
  tennable_scanner_sg_id                             = local.security_groups.Tennable_Scanner_Sg_Id
  log_group                                          = "" #already exists
  log_stream                                         = []
  cloudwatch_log_subscription_filter_role_arn        = "" #already exists
  cloudwatch_log_subscription_filter_destination_arn = "" #already exists
  project                                            = var.project
  region                                             = var.region
  environment                                        = var.environment
  instance_profile_name                              = var.name
  ec2_security_group_id                              = local.security_groups.Adpss_Sg_Id
  ec2_userdata                                       = <<EOF
      <powershell>
      $PhysicalDisks = Get-PhysicalDisk -CanPool $True
      if ($PhysicalDisks -ne $null) {
          New-Storagepool -FriendlyName "SasTempData" -StorageSubSystemFriendlyName "Windows Storage*" -PhysicalDisks $PhysicalDisks
          #Get-VirtualDisk -StoragePool (Get-StoragePool -FriendlyName "SasTempData")
          New-VirtualDisk -FriendlyName "SasTempData" -StoragePoolFriendlyName SasTempData -UseMaximumSize -ResiliencySettingName Simple -ProvisioningType Fixed
          Get-Disk | Where-Object OperationalStatus -eq 'Offline' |Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem NTFS -DriveLetter D -FriendlyName 'Local System'
          Write-EventLog -LogName Application -Source "Desktop Window Manager" -EventID 9997 -EntryType Information -Message "Completed Mounting SasTempData D Drive"  -Category 1 -RawData 10,20
      } else {
          Write-EventLog -LogName Application -Source "Desktop Window Manager" -EventID 9997 -EntryType Information -Message "No disks found to create pool. Check the disks in disk management."  -Category 1 -RawData 10,20
      }
    </powershell>
    <persist>true</persist>
  EOF
}


module "hcup" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas_aug20.availability_zone
  size              = 16000
  name              = "${var.name}-hcup"
  device_name       = "xvdh"
  instance_id       = module.sas_aug20.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}

/*module "meps" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas.availability_zone
  size              = 3000
  name              = "${var.name}-meps"
  device_name       = "xvdm"
  instance_id       = module.sas_nu.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}*/

/*
module "other_new" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas.availability_zone
  size              = 5100
  name              = "${var.name}-others-new"
  device_name       = "xvds"
  instance_id       = module.sas.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}
*/
module "meps_new" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas_aug20.availability_zone
  size              = 3000
  name              = "${var.name}-meps-new"
  device_name       = "xvdt"
  instance_id       = module.sas_aug20.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}

module "programs" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas_aug20.availability_zone
  size              = 300
  name              = "${var.name}-programs"
  device_name       = "xvdp"
  instance_id       = module.sas_aug20.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}

#---- this drive is to manage restricted folder access to groups only ---


module "restricted" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas.availability_zone
  size              = 50
  name              = "${var.name}-restricted"
  device_name       = "xvdr"
  instance_id       = module.sas.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}

#--provision T drive with 1TB Space EBS ColdStorage
/*
module "tdrive" {
  source            = "../../modules/pantheon-ebs/"
  availability_zone = module.sas.availability_zone
  size              = 8000
  name              = "${var.name}-vdrive"
  device_name       = "xvdv"
  type              = "sc1"
  instance_id       = module.sas.instance_id
  project           = var.project
  region            = var.region
  environment       = var.environment
}
*/
resource "aws_iam_role" "main" {
  name = "AWS_Events_Invoke_Action_On_EBS_Volume"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "events.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "main" {
  name = "AWS_Events_Invoke_Action_On_EBS_Volume"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateSnapshot"
        ],
        Effect = "Allow"
        Resource = [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

resource "aws_cloudwatch_event_rule" "main" {
  name                = "adpss_ebs_snapshots"
  schedule_expression = "cron(30 22 * * ? *)"
}

resource "aws_cloudwatch_event_target" "hcup" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "\"${module.hcup.ebs_volume_id}\""
}

/*resource "aws_cloudwatch_event_target" "meps" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "\"${module.meps.ebs_volume_id}\""
}*/

/*resource "aws_cloudwatch_event_target" "other" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "\"${module.other.ebs_volume_id}\""
}*/

resource "aws_cloudwatch_event_target" "programs" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "\"${module.programs.ebs_volume_id}\""
}

#create snapshots for new volumes and stop old ones
#new other volume
/*
resource "aws_cloudwatch_event_target" "other" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "vol-05c77d79939d904da"
  #"\"${module.other_new.vol-05c77d79939d904da}\""
}
*/
/*
resource "aws_cloudwatch_event_target" "other" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "\"${module.other_new.ebs_volume_id}\""
}
*/
resource "aws_cloudwatch_event_target" "meps" {
  rule     = aws_cloudwatch_event_rule.main.name
  arn      = "arn:aws:events:us-east-1:631203585119:target/create-snapshot"
  role_arn = aws_iam_role.main.arn
  input    = "\"${module.meps_new.ebs_volume_id}\""
}


resource "aws_network_interface" "sas_test_a20_nu" {
  subnet_id   = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  private_ips = ["10.38.1.70"]

  security_groups = [data.terraform_remote_state.vpn.outputs.vpn_security_group_id, local.security_groups.Tennable_Scanner_Sg_Id, local.security_groups.Adpss_Sg_Id, ]

  attachment {
    instance     = module.sas_test_a20.instance_id
    device_index = 1
  }
}
/*
resource "aws_network_interface" "sas_sccanner_test_nu" {
  subnet_id   = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  private_ips = ["10.38.1.63"]

  security_groups = [data.terraform_remote_state.vpn.outputs.vpn_security_group_id, local.security_groups.Tennable_Scanner_Sg_Id, local.security_groups.Adpss_Sg_Id, ]

  attachment {
    instance     = module.sas_sccanner_test.instance_id
    device_index = 1
  }
}
*/


/*resource "aws_volume_attachment" "sas_nu" {
  device_name = "xvdw"
  instance_id = module.sas_nu.instance_id
  volume_id = "vol-0f69cd1d9cd6797fa"
}*/
