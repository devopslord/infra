output "guard_duty_event_rule_name" {
  value = aws_cloudwatch_event_rule.main.name
}

output "guard_duty_event_rule_arn" {
  value = aws_cloudwatch_event_rule.main.arn
}