### Version v0.01 for adpss 

modules/pantheon-ec2/v0.01 

This version includes updates for reusing current resources while provisioning new ec2 instance v0.01. Based on the input values
set it either creates new resources or use existing ones. Specifically, the changes impact - loggroups, logstreams, securitygroups.

```
module "sas" {
  #module version
  source                  = "../../modules/pantheon-ec2/v0.01/" 

  #uses the loggroup defined in the cw agent on ec2
  log_group               = "" 
  #uses logstream defined in cw agent on ec2
  log_stream = [] 
  #utilizes existing cloudwatch subscription filter with the kinesis stream to push logs to s3 bucket   
  cloudwatch_log_subscription_filter_role_arn        = ""
  cloudwatch_log_subscription_filter_destination_arn = ""

  #use existing security group to attach to the ec2 instance passing in the security group id otherwise you can pass in empty string or comment it out. This is an optional field
  ec2_security_group_id = "sg-0acc0821efa1f7bcb"
}
```


Parameters for new