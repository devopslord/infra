output "vpn_dns_name" {
  value = aws_ec2_client_vpn_endpoint.main.dns_name
}

output "client_vpn_endpoint_id" {
  value = aws_ec2_client_vpn_endpoint.main.id
}

output "vpn_security_group_id" {
  value = aws_security_group.main.id
}
