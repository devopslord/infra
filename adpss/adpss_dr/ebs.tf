
#COPY SNAPSHOTS OVER REGION AND MOUNT

resource "aws_ebs_snapshot_copy" "pdrive" {
  source_region      = "us-east-1"
  source_snapshot_id = local.common_tags.copy_from.pdrive_ebs_snapshots
  encrypted          = true
}

resource "aws_ebs_volume" "pdrive" {
  availability_zone = "us-west-1c"
  encrypted         = true
  snapshot_id       = aws_ebs_snapshot_copy.pdrive.id
  kms_key_id        = "arn:aws:kms:us-west-1:631203585119:key/acbaf8a6-494f-470b-8117-395a3bb50e4b"
  size              = 300
  depends_on        = [aws_ebs_snapshot_copy.pdrive]
}



#"vol-00bcc0eaa5f0f38c6" = "xvdt" #m (m:/) drive
#"vol-09700083a7e341fac" = "xvds" #o (o:/) drive
#"vol-09492bfd2da074725" = "xvdp" #programs (p:/) drive
#"vol-06245475233cc54fc" = "xvdr" #restricted (r:/) drive
#"vol-04883b9198f973bbd" = "xvdh" #hcup (h:/)drive
resource "aws_volume_attachment" "pdrive" {
  device_name = "xvdp"
  volume_id   = aws_ebs_volume.pdrive.id
  instance_id = aws_instance.dr_instance.id

  depends_on = [aws_instance.dr_instance, aws_ebs_volume.pdrive]
}