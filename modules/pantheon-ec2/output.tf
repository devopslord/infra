output "role_arn" {
  value = aws_iam_role.main.arn
}
output "role_name" {
  value = aws_iam_role.main.name
}

output "security_group_id" {
  value = aws_security_group.main.id
}

output "security_group_name" {
  value = aws_security_group.main.name
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

output "instance_profile_name" {
  value = aws_iam_instance_profile.main.name
}
