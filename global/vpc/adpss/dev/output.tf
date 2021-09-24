output "vpc_id" {
  value = module.vpc.vpc_id
}

output "priv_subnet_ids" {
  value = module.vpc.priv_subnet_ids
}

output "pub_subnet_ids" {
  value = module.vpc.pub_subnet_ids
}

output "cloudwatch_log_subscription_filter_role_arn" {
  value = module.vpc.cloudwatch_log_subscription_filter_role_arn
}

output "cloudwatch_log_subscription_filter_destination_arn" {
  value = module.vpc.cloudwatch_log_subscription_filter_destination_arn
}
