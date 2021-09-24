#!/bin/bash

# ******
# SCRIPT NAME: paramstore.sh
# PURPOSE: This piece of code is to read the private selfsigned certificates and perform crud operations. Supply the CRUD type along with the paramter name.
# Ex: -r to read contents from parameter store and retrieve the values.
# Supported operations are -r, -c, -u, -d delete.
# AUTHOR: Sudheer Chadalavada
# DATE: 12/24/2020
# ******


method=$1
sslkey=$2
prefix=$3

if [[ ! $(aws --version) ]]; then
  echo "Install and Configure AWS CLI"
  exit 1
fi

#-------crud functions ---------
#created parameter store key/val with private,pub
create () {
  local file_name=$1
  local prefix_val=$2
  local prikey_val="$(cat ${file_name})"

  aws ssm put-parameter \
    --name "${prefix_val}${file_name}" \
    --description ${file_name} \
    --value  "${prikey_val}"\
    --type "String" \
    --tier Standard \
    --overwrite

  echo "invoked create() - successfully created parameter store key for $2$1"

  return
}

#get parameter store key/val with private,pub
read(){
  local file_name=$1
  local prefix_val=$2
  local response=$(aws ssm get-parameters --names "${prefix_val}${file_name}")
  echo "invoked read() - successfully deleted parameter $2$1"

  echo ${response} | jq '.Parameters[0].Value'

  return
}

#updated parameter store key/val with private,pub
update() {
  create $1 $2
  echo "invoked update() - successfully updated parameter store key for $2$1"
  return
}

delete() {
  #delete parameter store key/val with private,pub
  local param_name=$1
  local prikey="$(cat ${param_name})"
  aws ssm delete-parameter --name "$2$1"
  echo "invoked delete() - successfully deleted parameter $2$1"

  return
}
#--------end functions --------

#test.ahrq.gov and /hdasp/meps/dev
if [[ ! $sslkey || ! $prefix ]]; then
  echo "passdomain name and parameter path prefix"
  exit 1
fi
cd ./$sslkey

#files to create
filename="${sslkey}.pem"
csr="${sslkey}_csr.pem"
public_crt="${sslkey}_public.crt"

if [[ -f $filename ]] && [[ -f $csr ]] && [[ -f $public_crt ]]; then
  $method $filename $prefix
  $method $csr $prefix
  $method $public_crt $prefix
else
  echo "Create files before you write to parameter store."
  exit 1
fi