



#### TODO:
* the aws cli is configured for sudo need to make sure it works with jenkins service user and centos
* Create a aws config profile with ec2 metata
* test the command

#### Insall PIP and Python
``` 
sudo yum install python37
python --version
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
sudo ln -s /usr/bin/python3 /usr/bin/python
sudo /usr/local/bin/aws --version
sudo /usr/local/bin/aws configure
```


##### How to sync between s3 and meps dev
``` 
sudo su
cd /var/www/html/data_stats/download_data/pufs
/usr/local/bin/aws s3 sync s3://adass-meps-static-webcontent/dev/data_stats/download_data/pufs /var/www/html/data_stats/download_data/pufs --profile s3

```