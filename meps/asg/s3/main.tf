terraform {
  backend "s3" {
    bucket = "hdasp-terraform-state"
    key    = "meps/asg/s3/terraform.tfstate"
    region = "us-east-1"
  }
}
locals {
  s3_playbooks_bucket = "hdasp-inventory-playbooks"
}
resource "aws_s3_bucket_object" "object" {
  for_each = fileset("../integration-scripts/", "*")

  bucket = local.s3_playbooks_bucket
  key    = "cicd/${each.value}"
  source = "../integration-scripts/${each.value}"

  etag = filemd5("../integration-scripts/${each.value}")
}