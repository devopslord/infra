output "asg_role_arn" {
  value = aws_iam_role.asg.arn
}
output "asg_role_name" {
  value = aws_iam_role.asg.name
}

output "asg_ec2_policy_name" {
  value = aws_iam_policy.asg.name
}

output "asg_ec2_policy_arn" {
  value = aws_iam_policy.asg.arn
}

output "asg_ec2_instance_role_arn" {
  value = aws_iam_instance_profile.asg.arn
}
output "asg_ec2_instance_role_name" {
  value = aws_iam_instance_profile.asg.name
}

output "asg_launch_template_arn" {
  value = aws_launch_template.asg.arn
}

output "asg_launch_template_name" {
  value = aws_launch_template.asg.name
}

output "asg_launch_template_id" {
  value = aws_launch_template.asg.id
}

output "asg_launch_template_security_group_names" {
  value = aws_launch_template.asg.security_group_names
}

output "asg_launch_template_latest_version" {
  value = aws_launch_template.asg.latest_version
}

output "asg_targetgroup_arn" {
  value = aws_lb_target_group.asg.arn
}

output "asg_targetgroup_name" {
  value = aws_lb_target_group.asg.name
}

output "webserver_sg_id" {
  value = aws_security_group.webserver_sg.id
}
