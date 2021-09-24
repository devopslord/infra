//create policy ssm
//attach policy to existing instance role
//create vpc endpoint for ssm for security posture.
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas_aug20.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-ssm"))
}
resource "aws_vpc_endpoint" "ssm_ec2messages" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas_aug20.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-ec2messages"))

}
resource "aws_vpc_endpoint" "ssm_ec2" {
  vpc_id              = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name        = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [module.sas_aug20.security_group_id]
  subnet_ids          = [data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0]]
  private_dns_enabled = true
  auto_accept         = true

  tags = merge(local.common_tags, map("Name", "${var.name}-ec2"))
}
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = module.sas.role_name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}
resource "aws_s3_bucket" "ssm" {
  bucket = "hdasp-inventory-playbooks-${var.name}"
  acl    = "private"
  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  tags = merge(local.common_tags, map("Name", "${var.name}-ssm"))

}
resource "aws_s3_bucket_public_access_block" "ssm" {
  bucket                  = aws_s3_bucket.ssm.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "ssm" {
  bucket = aws_s3_bucket.ssm.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowingAllActionsForTheAccount",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::631203585119:root"
        },
        Action   = "s3:*",
        Resource = "${aws_s3_bucket.ssm.arn}/*"
        }, {
        Sid    = "AllowReadForSSM",
        Effect = "Allow",
        Principal = {
          Service = ["ssm.amazonaws.com"]
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.ssm.arn}/*"
      }
    ]
  })
}
resource "aws_iam_policy" "ssm" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowEC2RoleToAccessS3PlaybooksBucket",
        Effect   = "Allow",
        Action   = "s3:*",
        Resource = [aws_s3_bucket.ssm.arn, "${aws_s3_bucket.ssm.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  policy_arn = aws_iam_policy.ssm.arn
  role       = var.name
}