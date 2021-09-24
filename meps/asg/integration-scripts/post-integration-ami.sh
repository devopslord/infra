#!/bin/bash

#usage: post-integration-ami.sh {green instance name}
#input argument
instance_name=$1
jenkins_sg=$2
ws_sec_grp=$(/usr/local/bin/aws ssm get-parameter --name "${instance_name}-security-group-id" | jq '.Parameter.Value')

#local
declare imgid=""
declare instanceid=""

if [[ -z $instance_name ]]; then
  echo "Pass Integration Test Approved Instance Name Tag"
  exit 1
fi

instanceid=$(/usr/local/bin/aws ec2 describe-instances --filters Name=tag-value,Values="${instance_name}" Name=instance-state-name,Values=running | jq -r '.Reservations[0].Instances[0].InstanceId')
imgid=$(/usr/local/bin/aws ec2 describe-images --filter Name=name,Values="${instance_name}" | jq -r '.Images[0].ImageId')
if [[ -z ${instanceid} ]]; then
  echo "Could not find instance with the name ${1}. Rerun providing the instance name"
  exit 1
fi
#format
instanceid="${instanceid#\"}"
instanceid="${instanceid%\"}"
echo $instanceid

imgid="${imgid#\"}"
imgid="${imgid%\"}"
echo $imgid

create-image () {
  echo "  This step creates an image for instance ${1}."

  new_image_id=$(/usr/local/bin/aws ec2 create-image \
      --block-device-mappings 'DeviceName=/dev/sdh,Ebs={VolumeSize=150,DeleteOnTermination=true,VolumeType=gp2,Encrypted=true}' \
      --description "This is the latest Green AMI created following successful for Green Deployment" \
      --name "${1}" \
      --instance-id "${2}" \
      --no-reboot | jq -r '.ImageId')

  echo "$new_image_id"
  /usr/local/bin/aws ec2 wait image-available --image-ids ${new_image_id}
  /usr/local/bin/aws ssm put-parameter --name "${1}-image-id" --type "String" --value ${new_image_id} --overwrite

  #if [[ ! -z $new_image_id ]]; then
  #  echo "  terminating temporary provisioned ${1} instance "
  #  terminate-instance "${2}"
  #fi

}

delete-image() {
  echo "Deregister if image already exists"
  /usr/local/bin/aws ec2 deregister-image --image-id "${2}"
  echo "successfully deregistered ${1} image"
}

terminate-instance() {
  echo '  terminating instance'
  local terminateCode=$(/usr/local/bin/aws ec2 terminate-instances --instance-ids $1 | jq -r '.TerminatingInstances[0].CurrentState.Code')
  /usr/local/bin/aws ec2 wait instance-terminated --instance-ids $1
  echo '  successfully terminated instance'
}

detach_attach_cicd_securitygroup() {
  echo "  revoke-security-group-ingress rule ${1} to ${2}"
  aws ec2 revoke-security-group-ingress \
    --group-id ${1//\"} \
    --protocol tcp \
    --port 22 \
    --source-group ${2//\"} \
    --region us-east-1
  echo "  successfully revoked to sg ${2} from ${1}"
}

echo 'Post Deployment Provisioning'
echo 'Step1: Deregister the existing image to avoid conflict'
delete-image ${instance_name} ${imgid}
echo 'Step2: Create image with the name'
create-image ${instance_name} ${instanceid}
echo 'Step3: Revoke CICD Security Group Access to Instance Security Group'
detach_attach_cicd_securitygroup ${ws_sec_grp} ${jenkins_sg}

