How to use OpenSSL Tool

In order to create root CA, private and public certificate. Use

#### Create certificates
To create a selfsigned certificates for a given domain/subdomain for
internal purposes using openssl. Use the script to automate it. It will
create a directory with the domain name and creates the files in it.

``` 
$ ./gen_cert.sh {domain/subdomain}
$ ./gen_cert.sh meps-dev.ahrq.gov
```

#### CRUD to AWS Parameter Store
```
Create
$ ./paramstore.sh create dev.ahrq.gov /hdasp/meps/

Read
$ ./paramstore.sh read dev.ahrq.gov /hdasp/meps/

Update
$ ./paramstore.sh update dev.ahrq.gov /hdasp/meps/

delete
$ ./paramstore.sh delete dev.ahrq.gov /hdasp/meps/

```