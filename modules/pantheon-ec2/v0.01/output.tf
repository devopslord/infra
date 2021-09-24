output "security_group_id" {
  value = (var.ec2_security_group_id != "") ? var.ec2_security_group_id: aws_security_group.main[0].id
}

output "security_group_name" {
  value = (var.ec2_security_group_id != "") ? var.ec2_security_group_id: aws_security_group.main[0].name
}

output "availability_zone" {
  value = aws_instance.main.availability_zone
}

output "instance_id" {
  value = aws_instance.main.id
}

output "primary_network_interface_id" {
  value = aws_instance.main.primary_network_interface_id
}
