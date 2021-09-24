#!/bin/bash

#******
# SCRIPT NAME: gencert.sh
# PURPOSE: The purpose of this bash script is to create self-signed certificates for a given domain name.
# AUTHOR: Sudheer Chadalavada
# DATE: 12/24/2020
#******

if [[ ! $(openssl version) ]]; then
  echo "Install OpenSSL before running the commands"
  exit 1
fi

create_certificate () {
  #input argument required ex: test.panth.com
  sslkey=$1

  #files to create
  filename="${sslkey}.pem"
  csr="${sslkey}_csr.pem"
  public_crt="${sslkey}_public.crt"

  #check openssl exists
  if [[ ! $sslkey ]]; then
    echo "Enter subdomain as only argument (ex: test.panth.com)"
    exit 1
  fi
  mkdir $sslkey
  cd $sslkey
  # domain already created
  if [[ -f ${filename} ]] && [[ -f ${csr} ]] && [[ -f ${public_crt} ]]; then
    echo "This domain is already processed. Use another name or delete the created files."
    exit 1
  else
    #Create Private key
     openssl genrsa 2048 > ${filename}
    #Create CSR
    if [[ -e ${filename} ]]; then
        openssl req -new -key ${filename} -out ${csr}
        echo "Created PrivateKey and CSR"
    else
      echo "Failed to create PrivateKey and CSR"
      exit 1
    fi

    if [[ -e ${filename} && -e ${csr} ]]; then
        openssl x509 -req -days 365 -in ${csr} -signkey ${filename} -out ${public_crt}
        echo "Created public certificate"
    else
      echo "Failed to create public certificate"
      exit 1
    fi
  fi
}



openssl_exists() {
  echo "say hello"
}

declare -xf openssl_exists