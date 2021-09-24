#!/bin/bash

#asg_name='meps-asg-green-prod'
#jenkins_sg='sg-0d5570227b55367d4'

asg_name=$1
jenkins_sg=$2

if [[ -z ${asg_name} ]]; then
  echo 'Required autoscaling group name'
  exit 1
fi;

if [[ -z ${jenkins_sg} ]]; then
  echo 'Required Jenkins CICD Security Group Id'
  exit 1
fi;

priv_ip=$(/usr/local/bin/aws ssm get-parameter --name "${asg_name}-private-ip" | jq '.Parameter.Value')
instance_sg=$(/usr/local/bin/aws ssm get-parameter --name "${asg_name}-security-group-id" | jq '.Parameter.Value')
instance_profile=$(/usr/local/bin/aws ssm get-parameter --name "${asg_name}-instance-profile-name" | jq '.Parameter.Value')
lt_name=$(/usr/local/bin/aws ssm get-parameter --name "${asg_name}-launch-template-name" | jq '.Parameter.Value')
instance_name=$(/usr/local/bin/aws ssm get-parameter --name "${asg_name}-instance-name" | jq '.Parameter.Value')
subnet_id=$(/usr/local/bin/aws ssm get-parameter --name "${asg_name}-subnet-id" | jq '.Parameter.Value')

#check-n-provision(${instance_name} ${instance_profile} ${instance_sg} ${jenkins_sg} ${subnet_id} ${priv_ip})
check-n-provision() {
  echo "Step 1: Check the infrastructure"
  imageid=$(/usr/local/bin/aws ec2 describe-images --filter Name=name,Values="${1}" | jq -r '.Images[0].ImageId')
  if [[ -z ${imageid} ]]; then
    echo "  Create an An Image and provide the image name to proceed."
    exit 1
  fi
  echo "  Requirements: Image found ${imageid}"

  #terminate instance by priv_ip (slave node)
  terminate-instance ${priv_ip}

  #create-instance(imageid, instance_profile, instance_name, instance_sg, subnet_id, priv_ip )
  create-instance ${imageid} ${2} ${1} ${3} ${4} ${5} ${6}

  #attach jenkins security group to all ssh ingress to slave
  attach_cicd_securitygroup ${3} ${4}

}

#usage: terminate-instance(ipaddress)
terminate-instance() {
  echo "Step 2: Terminate Instance"
  local instance_ids=$(/usr/local/bin/aws ec2 describe-instances --filters Name=network-interface.addresses.private-ip-address,Values="${1}" | jq -r '.Reservations[].Instances[].InstanceId')
  echo "  Terminate slave instance/s ${instance_ids}"
  for instance_id in ${instance_ids}
  do
    terminateCode=$(/usr/local/bin/aws ec2 terminate-instances --instance-ids ${instance_id} | jq -r '.TerminatingInstances[0].CurrentState.Code')
    /usr/local/bin/aws ec2 wait instance-terminated --instance-ids ${instance_id}
  done
  echo "  Terminated CICD Slave instance"

}

#create-instance(imageid, instance_profile, instance_name, instance_sg, jenkins_sg, subnet_id, priv_ip )
create-instance () {
  echo "Step 3: Provision and Configure Instance"
  echo "  Create-Instance(): provisioning instance from $1 image id"

  local newinstance=$(/usr/local/bin/aws ec2 run-instances \
      --image-id "${1//\"}"  \
      --count 1 \
      --instance-type t2.small \
      --iam-instance-profile Name="${2//\"}" \
      --key-name pantheon \
      --security-group-ids "${4//\"}"  \
      --subnet-id "${6//\"}" \
      --private-ip-address "${7//\"}" \
      --tag-specifications "ResourceType=instance, Tags=[{Key=Name,Value=$3}]")

  instanceid=$(echo ${newinstance} | jq -r '.Instances[0].InstanceId')
  echo "  new instance id=$instanceid provisioning in process"
  /usr/local/bin/aws ec2 wait instance-status-ok --instance-ids $instanceid
  echo "  new instance id=$instanceid provisioning complete"

  #put to parameterstore
  echo "Step 4: Update SSM ${3//\"}-instance-id parameter store with ${instanceid}"
  /usr/local/bin/aws ssm put-parameter --name "${3//\"}-instance-id" --type "String" --value ${instanceid} --overwrite
}

attach_cicd_securitygroup() {
  echo "Step 5: Attach Jenkins CICD Security Group to Slave SG"
  echo "  attach_cicd_securitygroup rule ${1} to ${2}"
  aws ec2 authorize-security-group-ingress \
    --group-id ${1//\"} \
    --protocol tcp \
    --port 22 \
    --source-group ${2//\"} \
    --region us-east-1

}

detach_attach_cicd_securitygroup() {
  echo "Step 6: Post Image Creation Detach the CICD Secuirty group"
  echo "  revoke-security-group-ingress rule ${1} to ${2}"
  aws ec2 revoke-security-group-ingress \
    --group-id ${1//\"} \
    --protocol tcp \
    --port 22 \
    --source-group ${2//\"} \
    --region us-east-1
  echo "  revoked to sg ${2} from ${1}"
}

check-n-provision ${instance_name} ${instance_profile} ${instance_sg} ${jenkins_sg} ${subnet_id} ${priv_ip}