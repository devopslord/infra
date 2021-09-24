output "vpcflowlog_id" {
  value = aws_flow_log.vpc_flow_log.id
}

output "vpcflowlog_iam_role_arn" {
  value = aws_iam_role.vpc_flow_log.arn
}

#pass policy
output "vpcflowlog_pass_policy_id" {
  value = aws_iam_policy.pass_policy.id
}

output "vpcflowlog_pass_policy_arn" {
  value = aws_iam_policy.pass_policy.arn
}

#cw policy
output "vpcflowlog_cw_id" {
  value = aws_cloudwatch_log_group.cloud_watch.id
}

output "vpcflowlog_cw_arn" {
  value = aws_cloudwatch_log_group.cloud_watch.arn
}
