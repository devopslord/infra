
#--Windows Server 2016 Extras Source Media Drive.
#Usage: Create the resource and attach to WIdnows volume to install any features


/*
resource "aws_ebs_volume" "win_media" {
  availability_zone = module.sas.availability_zone
  size              = 10
  snapshot_id       = "snap-22da283e"
  type              = "gp2"
  encrypted         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-win-media"))
}

resource "aws_volume_attachment" "main" {
  device_name = "xvdw"
  volume_id   = aws_ebs_volume.win_media.id
  instance_id = module.sas.instance_id
}
*/