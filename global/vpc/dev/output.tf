output "vpc_id" {
  value = module.vpc.vpc_id
}

output "priv_subnet_ids" {
  value = module.vpc.priv_subnet_ids
}

output "pub_subnet_ids" {
  value = module.vpc.pub_subnet_ids
}

output "db_subnet_group_name" {
  value = aws_db_subnet_group.main.name
}

output "alb_logs_s3_bucket" {
  value = aws_s3_bucket.main.bucket
}

output "cloudwatch_log_subscription_filter_role_arn" {
  value = module.vpc.cloudwatch_log_subscription_filter_role_arn
}

output "cloudwatch_log_subscription_filter_destination_arn" {
  value = module.vpc.cloudwatch_log_subscription_filter_destination_arn
}
