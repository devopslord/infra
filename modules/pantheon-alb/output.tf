output "security_group_id" {
  value = aws_security_group.main.id
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "aws_lb_listener_https_arn" {
  value = aws_lb_listener.https.arn
}
