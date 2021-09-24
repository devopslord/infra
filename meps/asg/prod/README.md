

Provisiong Autoscaling Group.

Prerequisites:
1. The name should have appname - deployment type - environment (follow the sequence.). Ex:
meps-green-prod
2. Using terraforms provision the infrastructure
``` 
terraform apply
```
3. Run the post_terraform_apply.sh
```
chmod +x post_terraform_apply.sh 
./post_terraform_apply.sh
```

4. Run S3 terraform apply to upload the output.


