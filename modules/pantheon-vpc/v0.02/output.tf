output "vpc_id" {
  value = aws_vpc.main.id
}

output "priv_subnet_ids" {
  value = aws_subnet.priv.*.id
}

output "pub_subnet_ids" {
  value = aws_subnet.pub.*.id
}

output "priv_route_table_id" {
  value = aws_route_table.priv.id
}

output "pub_route_table_id" {
  value = aws_route_table.pub.id
}

output "cloudwatch_log_subscription_filter_role_arn" {
  value = aws_iam_role.cloudwatch.arn
}

output "cloudwatch_log_subscription_filter_destination_arn" {
  value = aws_kinesis_firehose_delivery_stream.main.arn
}

output "cidr_block" {
  value = var.cidr_block
}

