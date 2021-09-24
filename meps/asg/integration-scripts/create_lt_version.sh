#!/bin/bash

# usage(): create_lt_version launchtemplateid imageid versiondescription
# ex: create_lt_version.sh lt-0ae12f514c2e1f7c9 ami-00c2b44af8a5693d7 "A New Green Meps Instance for Autoscaling"

launch_template_name=$1
green_image_id=$2

create_launch_template() {
  templatename="*${1}*"
  templateid=$(/usr/local/bin/aws ec2 describe-launch-templates --filters "Name=launch-template-name,Values=${templatename}" | jq -r '.LaunchTemplates[0].LaunchTemplateId')
  if [[ -z ${templateid} ]]; then
    echo "  check the template name provided. Could not find template id for the given name"
    exit 1
  fi
  echo '  Creating new launch template version'
  version_nos=$(/usr/local/bin/aws ec2 describe-launch-template-versions --launch-template-id ${templateid} | jq -r '.LaunchTemplateVersions[].VersionNumber')
  max_version=1
  for n in ${version_nos} ; do
      if [[ $n > $max_version ]]; then
        max_version=$n;
      fi
  done
  echo "  Gather the Template Version ${max_version} "
  /usr/local/bin/aws ec2 create-launch-template-version \
                  --launch-template-id ${templateid} \
                  --source-version ${max_version} --launch-template-data ''{\"ImageId\":\"${2}\"}''

  echo "  Update the Launch Template Version "


}
echo 'Step1: Create Launch Template Version and Update the Autoscaling'
create_launch_template ${launch_template_name} ${green_image_id}
echo "Completed new launch template version"