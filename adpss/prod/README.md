### ADPSS Windows Monitoring and Logging with Cloudwatch

The following section outlines the process, checks and validations that needs to be done pre and post 
maintenance of the ADPSS Server.

###### Pre-Checks
* Create an AMI of the current EC2 Instance
* Run the terraform plan (to identify all resources that will be provisioned ahead)

###### Setup
* Copy the config json to C:\Program Files\Amazon\AmazonCloudWatchAgent\config.json (config.json is located in scripts directory of the repo).
* Below are the steps to Run powershell script 
```html
$Start-Process powershell -Verb runAs Administrator
$cd 'C:\Program Files\Amazon\AmazonCloudWatchAgent\'
$.\amazon-cloudwatch-agent-ctl.ps1 -a fetch-config -m ec2 -c file:'C:\Program Files\Amazon\AmazonCloudWatchAgent\config.json' -s
$.\amazon-cloudwatch-agent-ctl.ps1 -a status
```
* The status should be Running, go to cloudwatch metrics for metrics view and loggroup adpss/ for streaming logs.

----------
#### Data Archival Process
Use instance profile role with sufficient permissions to gain access to specific s3 bucket with bucket policies. This is the ideal approach instead of iam user profile configuration on the ec2 instance to avoid access key or credential leaks.

###### Data Ingestion

* Set policy permissions on the role to allow ec2 instance to make sts calls.
```
    {
        Sid = "AllowEC2AdpssCLIToMakeSTSCallsOnInstanceRole",
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = "arn:aws:iam::631203585119:role/adpss"
    }

```
* Setup S3 bucket to copy data from adpss server to s3 bucket 
* Set the number of concurrent s3 requests allowed to put. 
```
aws configure set default.s3.max_concurrent_requests 20
``` 
* Complete the copying folders,files and subfolders using aws cli commands
```
aws s3 cp {folder} s3://hdasp-adpss-archive/{folder} --recursive --profile s3
```
* On S3, change the class to Glacier Deep Archive

###### Data Retrieval
* Enable retrieval and set days for the download to be available (~10days)
* Once download is available,run s3 script to download from bucket to adpss server

* step 1: List the objects
```
aws s3api list-objects --bucket hdasp-adpss-archive --profile s3
aws s3 sync s3://hdasp-adpss-archive/QDR ./QDR --profile s3

archive/QDR/Deliv2122017/NEDS+MHSA+tables+for+NHQR+(All+Ages+Principal+DX)+-+2007-2015+12102017.xlsx
```
* Step 2: Restore the object (Restoration can happen only at the object level.)
```
aws s3api list-objects --bucket hdasp-adpss-archive --key archive/QDR/Deliv2122017/NEDS+MHSA+tables+for+NHQR+(All+Ages+Principal+DX)+-+2007-2015+12102017.xlsx 
--restore-request '{"Days:25, "Glacier}'--profile s3
 
```


``` 
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowRoleToReadTheBucket",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::631203585119:role/adpss"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::hdasp-adpss-repo",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "10.38.1.60"
                }
            }
        },
        {
            "Sid": "AllowRoleToReadTheBucketDevADPSS",
            "Effect": "Allow",
            "Principal": {
                "AWS": "AROAZF5VKLRP2OWJAU47X"
            },
            "Action": "s3:ListBucket",
            "Resource": "arn:aws:s3:::hdasp-adpss-repo",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "10.39.1.47"
                }
            }
        },
        {
            "Sid": "AllowMepsProfileToReadTheBucketDevADPSSObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "AROAZF5VKLRP2OWJAU47X"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::hdasp-adpss-repo/*",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "10.39.1.47"
                }
            }
        },
        {
            "Sid": "AllowMepsProfileToReadTheBucketObjects",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::631203585119:role/adpss"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::hdasp-adpss-repo/*",
            "Condition": {
                "IpAddress": {
                    "aws:SourceIp": "10.38.1.60"
                }
            }
        }
    ]
}
```