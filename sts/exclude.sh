#may need to unset your default variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_DEFAULT_REGION
unset AWS_SESSION_TOKEN

export AWS_ACCESS_KEY_ID=AKIxxxxxxxx
export AWS_SECRET_ACCESS_KEY=l6tpT/WprIzxbUODxxxxxxxxxx
export AWS_DEFAULT_REGION=us-east-1

aws sts get-session-token --serial-number arn:aws:iam::631203585119:mfa/lchinedu@panth.com --token-code 896371 > sts.json
#aws sts get-session-token --serial-number arn:aws:iam::631203585119:mfa/aschadalavada@panth.com --token-code 161880 > sts.json
