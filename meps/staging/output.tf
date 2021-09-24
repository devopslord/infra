output "tomcat_security_group_id" {
  value = module.tomcat.security_group_id
}

output "iis_security_group_id" {
  value = module.iis.security_group_id
}

output "tomcat_availability_zone" {
  value = module.tomcat.availability_zone
}

output "iis_availability_zone" {
  value = module.iis.availability_zone
}
