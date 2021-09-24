resource "aws_vpc" "main" {
  cidr_block                       = var.cidr_block
  enable_dns_support               = true
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = var.assign_generated_ipv6_cidr_block

  tags = {
    Name = var.name
  }
}

resource "aws_subnet" "priv" {
  count = var.az_count

  vpc_id               = aws_vpc.main.id
  cidr_block           = cidrsubnet(var.cidr_block, 8, (count.index + 1))
  availability_zone_id = "use1-az${(count.index + 1)}"
  ipv6_cidr_block      = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, (count.index + 1))
  tags = {
    Name                                            = "${var.name}-priv-0${(count.index + 1)}"
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
  }
}

resource "aws_subnet" "pub" {
  count = var.az_count

  vpc_id               = aws_vpc.main.id
  cidr_block           = cidrsubnet(var.cidr_block, 8, "${(count.index + 1)}0")
  availability_zone_id = "use1-az${(count.index + 1)}"
  ipv6_cidr_block      = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, "${(count.index + 1)}0")
  tags = {
    Name = "${var.name}-pub-0${(count.index + 1)}"
  }
}

resource "aws_vpc_dhcp_options" "main" {
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = var.name
  }
}

resource "aws_vpc_dhcp_options_association" "main" {
  vpc_id          = aws_vpc.main.id
  dhcp_options_id = aws_vpc_dhcp_options.main.id
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.name
  }
}

resource "aws_eip" "nat_gateway" {
  count = var.eip == "" ? 1 : 0
  vpc   = true

  tags = {
    Name = "${var.name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = (var.eip == "" ? aws_eip.nat_gateway[0].id : var.eip)
  subnet_id     = aws_subnet.pub[0].id

  tags = {
    Name = var.name
  }
}

resource "aws_route_table" "priv" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-priv"
  }
}

resource "aws_route" "nat" {
  route_table_id         = aws_route_table.priv.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}

resource "aws_route_table_association" "priv" {
  count = var.az_count

  subnet_id      = aws_subnet.priv[count.index].id
  route_table_id = aws_route_table.priv.id
}

resource "aws_route_table" "pub" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name}-pub"
  }
}

resource "aws_route" "igw" {
  route_table_id         = aws_route_table.pub.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route" "igw_ipv6" {
  route_table_id         = aws_route_table.pub.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "pub" {
  count = var.az_count

  subnet_id      = aws_subnet.pub[count.index].id
  route_table_id = aws_route_table.pub.id
}

resource "aws_s3_bucket" "main" {
  bucket = "hdasp-${var.name}-log-storage"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "firehose" {
  name = "${var.name}-firehose-to-s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose" {
  name = "${var.name}-firehose-to-s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload",
          "s3:RestoreObject",
          "s3:DeleteObject"
        ]
        Effect   = "Allow"
        Resource = "${aws_s3_bucket.main.arn}/*"
      },
      {
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Effect   = "Allow"
        Resource = aws_s3_bucket.main.arn
      },
      {
        Action = [
          "s3:ListAllMyBuckets",
          "s3:HeadBucket"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose" {
  role       = aws_iam_role.firehose.name
  policy_arn = aws_iam_policy.firehose.arn
}

resource "aws_kinesis_firehose_delivery_stream" "main" {
  name        = "${var.name}-cw-to-s3"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.firehose.arn
    bucket_arn = aws_s3_bucket.main.arn
  }
}

resource "aws_iam_role" "cloudwatch" {
  name = "${var.name}-cw-to-firehose"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "logs.us-east-1.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "cloudwatch" {
  name = "${var.name}-cw-to-firehose"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "firehose:*"
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_firehose_delivery_stream.main.arn
      },
      {
        Action = [
          "iam:PassRole"
        ]
        Effect   = "Allow"
        Resource = aws_iam_role.cloudwatch.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = aws_iam_policy.cloudwatch.arn
}
