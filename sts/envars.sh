echo 'export AWS_ACCESS_KEY_ID='`cat sts.json | jq -r '.Credentials.AccessKeyId'` >> sts.json
echo 'export AWS_SECRET_ACCESS_KEY='`cat sts.json | jq -r '.Credentials.SecretAccessKey'`  >> sts.json
echo 'export AWS_SESSION_TOKEN='`cat sts.json | jq -r '.Credentials.SessionToken'`  >> sts.json
echo 'export AWS_DEFAULT_REGION=us-east-1'  >> sts.json