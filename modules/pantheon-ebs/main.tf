resource "aws_ebs_volume" "main" {
  availability_zone = var.availability_zone
  size              = var.size
  encrypted         = var.encrypted
  type              = var.type

  tags = {
    Name        = var.name
    Project     = var.project
    Location    = var.region
    Environment = var.environment
  }
}

resource "aws_volume_attachment" "main" {
  device_name = var.device_name
  volume_id   = aws_ebs_volume.main.id
  instance_id = var.instance_id
}