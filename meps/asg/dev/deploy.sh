#!/bin/bash
# ###CI Stage process
#1. method=integration stage Create an instance from previous production version of AMI (input = instancename, ami id, instance instance_profile, target group arn) and return ipaddress
#2. method=integration Download Nexus artifact and replace the existing application
#3. Post CI Stage (Requires approval in CICD pipeline)
#4. deployment stage to Create an ami from the instance

#VARIABLES
stage=$1
method=$2
instance_name=$3
image_id=$4
instance_profile=$5
instanceid=$3 #initilize for create-image

#usage 1.  ./deploy.sh integration-stage create-instance {instance name} {ami id to create from} {instance profile name}
#usage example.  ./deploy.sh integration-stage create-instance meps-test ami-05da26671d7361078 hdasp-jenkins

#usage 2. ./deploy.sh deployment-stage create-image {instance id}
#usage 2 example. ./deploy.sh deployment-stage create-image i-00b81d0f68c44b652


if [[ ! $(aws --version) ]]; then
  echo "Install and Configure AWS CLI"
  exit 1
fi

if [[ $stage != "integration-stage" && $stage != "deployment-stage" ]]; then
  echo "The first argument should be either $stage."
  exit 1
fi

if [[ $method != "create-instance" && $method != "create-image" ]]; then
  echo "The first argument should be either $method."
  exit 1
fi

get_instance_private_ip () {
  privateip=$(aws ec2 describe-instances --instance-ids $1 | jq -r '.Reservations[0].Instances[0].PrivateIpAddress')
  echo "${privateip}"
}

create-instance () {
  local instance=$(aws ec2 describe-instances --filters Name=image-id,Values=$1 Name=tag-value,Values=$3 | jq -r '.Reservations[0].Instances[0]')
  instanceid=$(echo ${instance} | jq -r '.InstanceId')
  if [[ -z $instanceid || $(echo ${instance} | jq -r '.State.Name') == "terminated" ]]; then
      echo "provisioning meps instance from $1 image id"
      local newinstance=$(aws ec2 run-instances \
          --image-id $1  \
          --count 1 \
          --instance-type t2.small \
          --iam-instance-profile Name=$2 \
          --key-name pantheon \
          --security-group-ids sg-089cb71ddf0561d5a \
          --subnet-id subnet-0510bdf205bad2020 \
          --tag-specifications "ResourceType=instance, Tags=[{Key=Name,Value=$3}]")

      instanceid=$(echo ${newinstance} | jq -r '.Instances[0].InstanceId')
      echo "new instance id=$instanceid provisioning in process"
      aws ec2 wait instance-status-ok --instance-ids $instanceid
      echo "new instance id=$instanceid provisioning complete"
      echo $get_instance_private_ip $instanceid

      #aws elbv2 register-targets \
#    --target-group-arn arn:aws:elasticloadbalancing:us-east-1:631203585119:targetgroup/meps-dev-green-tg/834588f9566252d1 \
#    --targets Id=i-0cb94250774fb8963

  else
    echo "already exists $instanceid"
  fi

}

create-image () {
  image_id=$(aws ec2 create-image \
      --block-device-mappings 'DeviceName=/dev/xvda,Ebs={VolumeSize=20,DeleteOnTermination=true,VolumeType=gp2,Encrypted=true}' \
      --description "This is the latest AMI created following green deployment testing for MEPS application." \
      --name "meps-bluegreen-$1" \
      --instance-id $1 \
      --no-reboot | jq -r '.ImageId')

  echo "$image_id"
}
#---------end helpers-------

if [[ "${stage}" == "integration-stage" ]]; then
  if [[ "$image_id" != " " && "$instance_profile" != " " ]]; then
    $method $image_id $instance_profile $instance_name
  else
    echo "Enter image id, instance profile name"
    exit 1
  fi
elif [[ "${stage}" == "deployment-stage" ]]; then
  echo "creating ami for instance id=$instanceid"
  $method $instanceid
else
  echo "The deployment type could be either integration-stage or deployment-stage"
fi






