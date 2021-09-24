#!/bin/bash -x

terraform show -json > output.json

#NEED TO HARDCODE FOR HDASP JENKINS CICD SECURITY GROUP. THE JENKINS TO COMMUNICATE WITH SLAVE NODES
jenkins_sg='sg-0d5570227b55367d4'
instance_sg=$(jq '.values.root_module.resources[] | select(.address=="aws_security_group_rule.webserver_alb_sg_rule") | .values.security_group_id' output.json | tr -d \")
instance_profile=$(jq '.values.root_module.child_modules[].resources[] | select(.address=="aws_iam_instance_profile.asg") | ."values"."name"' output.json | tr -d \")
set subns==$(jq '.values.root_module.resources[] | select(.address=="data.terraform_remote_state.vpc") | ."values"."outputs"."priv_subnet_ids"' output.json | tr -d \")

template='{"jenkins_sg":"%s", "instance_sg":"%s", "instance_profile":"%s", "subnet_id":"%s"}'
json_str=$(printf  "$template" "$jenkins_sg" "$instance_sg" "$instance_profile" "${3%,*}")
echo $json_str > ../integration-scripts/${instance_profile}.json

rm -f ./output.json