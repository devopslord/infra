terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "adpss_dr/us_west/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-west-1"
}

locals {
  common_tags = {

    copy_from = {
      source_ami           = var.adpss_ec2_src_ami          #us-east-1 source image ami id
      pdrive_ebs_snapshots = var.pdrive_ebs_src_snapshot_id #us-east-source snapshot ids of each mapped volume
    }

    Project     = "adpss"
    Location    = "us-west-1" #dr region to launch
    Environment = "production"

    ec2_instance_type    = "i3.8xlarge"
    ec2_key_name         = "pantheon"
    ec2_termination      = true
    ec2_public_ip        = false
    ec2_instance_profile = "adpss"
    ec2_security_groups  = [var.vpn_securitygroup_id]
  }
}


#------READ DATA SOURCE --------

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/adpss/us_west/terraform.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "vpn" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpn/us_west/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_network_acls" "nacl" {
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id
}
#------END READ DATA SOURCE --------

#---- CREATE RESOURCE ------

resource "aws_ami_copy" "adpss-dr-ami" {
  name              = "adpss"
  source_ami_id     = local.common_tags.copy_from.source_ami
  source_ami_region = "us-east-1"
  encrypted         = true
}

resource "aws_security_group" "dr_instance" {
  name   = var.name
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = var.name
  }
}

resource "aws_security_group_rule" "main_inbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  self              = "true"
  security_group_id = aws_security_group.dr_instance.id
}

resource "aws_security_group_rule" "vpn" {

  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "all"
  source_security_group_id = local.common_tags.ec2_security_groups[0]
  security_group_id        = aws_security_group.dr_instance.id
}

resource "aws_instance" "dr_instance" {
  ami                     = aws_ami_copy.adpss-dr-ami.id
  instance_type           = local.common_tags.ec2_instance_type
  key_name                = local.common_tags.ec2_key_name
  vpc_security_group_ids  = local.common_tags.ec2_security_groups
  iam_instance_profile    = local.common_tags.ec2_instance_profile
  subnet_id               = data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]
  disable_api_termination = local.common_tags.ec2_termination
  security_groups         = [aws_security_group.dr_instance.id]
  private_ip              = "10.38.1.60"
  user_data               = <<EOF
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
  depends_on              = [aws_ami_copy.adpss-dr-ami]
}


#add nacl rules
# Outbound Connections for sftp.impaqint.com
resource "aws_network_acl_rule" "impaq" {
  network_acl_id = data.aws_network_acls.nacl.id
  rule_number    = 1
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "192.108.127.41/32"
}

# Outbound Connections for sftp.s-3.net
resource "aws_network_acl_rule" "sss" {
  network_acl_id = data.aws_network_acls.nacl.id
  rule_number    = 2
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "198.136.164.212/32"
}

# Outbound Connections for eft.ahrq.gov
resource "aws_network_acl_rule" "ahrq" {
  network_acl_id = data.aws_network_acls.nacl.id
  rule_number    = 3
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "162.99.46.83/32"
}

# Internal VPC Outbound Connections
resource "aws_network_acl_rule" "vpc" {
  network_acl_id = data.aws_network_acls.nacl.id
  rule_number    = 4
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.38.0.0/16"
}

# Tenable Scanner VPC
resource "aws_network_acl_rule" "tenable_scanner" {
  network_acl_id = data.aws_network_acls.nacl.id
  rule_number    = 5
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "10.31.1.0/24"
}
