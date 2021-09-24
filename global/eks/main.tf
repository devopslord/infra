terraform {
  backend "s3" {
    bucket  = "hdasp-terraform-state"
    key     = "global/eks/terraform.tfstate"
    region  = "us-east-1"
    profile = "hdasp"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  profile = "hdasp"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "hdasp-terraform-state"
    key    = "global/vpc/prod/terraform.tfstate"
    region = "us-east-1"
  }
}

/*resource "aws_iam_role" "eks" {
  name = "hdasp-eks"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.name}-eks"
  }
}

data "aws_iam_policy" "eks_cluster_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = data.aws_iam_policy.eks_cluster_policy.arn
}

data "aws_iam_policy" "eks_service_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  role       = aws_iam_role.eks.name
  policy_arn = data.aws_iam_policy.eks_service_policy.arn
}

resource "aws_security_group" "main" {
  name   = "hdasp-eks-cluster"
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name = "${var.name}-eks"
  }
}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}
resource "aws_security_group_rule" "main" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "/aws/eks/${var.name}/cluster"
  retention_in_days = 7

  tags = {
    Name = "${var.name}-eks"
  }
}

resource "aws_eks_cluster" "main" {
  name                      = var.name
  role_arn                  = aws_iam_role.eks.arn
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [aws_security_group.main.id]
    subnet_ids = [
      data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0],
      data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1],
      #data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2] # Unavailable at this time: Cannot create cluster 'hdasp' because us-east-1e, the targeted availability zone, does not currently have sufficient capacity to support the cluster
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
    aws_cloudwatch_log_group.main
  ]

  tags = {
    Name = var.name
  }
}

#resource "aws_iam_role" "fargate" {
#  name = "${var.name}-fargate"
#
#  assume_role_policy = jsonencode({ 
#    Version   = "2012-10-17"
#    Statement = [{
#      Action    = "sts:AssumeRole"
#      Effect    = "Allow"
#      Principal = {
#        Service = "eks-fargate-pods.amazonaws.com"
#      }
#    }]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
#  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
#  role       = aws_iam_role.fargate.name
#}
#
#resource "aws_eks_fargate_profile" "main" {
#  cluster_name           = aws_eks_cluster.main.name
#  fargate_profile_name   = var.name
#  pod_execution_role_arn = aws_iam_role.fargate.arn
#  subnet_ids             = data.terraform_remote_state.vpc.outputs.priv_subnet_ids
#
#  selector {
#    namespace = "kube-system"
#  }
#
#  selector {
#    namespace = "cicd"
#  }
#}

resource "aws_iam_role" "node_group" {
  name = "${var.name}-node-group"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids = [
    data.terraform_remote_state.vpc.outputs.priv_subnet_ids[0],
    data.terraform_remote_state.vpc.outputs.priv_subnet_ids[1],
    #data.terraform_remote_state.vpc.outputs.priv_subnet_ids[2] # Unavailable at this time: Cannot create cluster 'hdasp' because us-east-1e, the targeted availability zone, does not currently have sufficient capacity to support the cluster
  ]

  remote_access {
    ec2_ssh_key               = "pantheon"
    source_security_group_ids = [aws_security_group.main.id]
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = {
    Name = "${var.name}-eks-node-group"
  }
}*/
