# Data sources for AWS partitions and caller identity
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

# EKS Cluster Service Role
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# EKS Cluster Service Role Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# Additional policy for VPC resource controller
resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

# EKS Node Group Service Role
resource "aws_iam_role" "eks_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# EKS Node Group Policy Attachments
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

# OpenID Connect Provider for IRSA (IAM Roles for Service Accounts)
data "tls_certificate" "eks_oidc" {
  count = var.enable_irsa ? 1 : 0
  url   = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc[0].certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-eks-irsa"
    }
  )
}

# IAM Role for Worker Service Account  
resource "aws_iam_role" "worker_service_role" {
  count = var.enable_irsa ? 1 : 0
  name = "${var.cluster_name}-worker-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"  
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc[0].arn
      }
      Condition = {
        StringEquals = {
          # Only allow the worker service account to assume this role
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:healthmetrics:worker-service-account"
        }
      }
    }]
  })

  tags = var.tags
}

# SQS Policy for Worker
resource "aws_iam_role_policy" "worker_sqs_policy" {
  count = var.enable_irsa ? 1 : 0
  name = "worker-sqs-policy"
  role = aws_iam_role.worker_service_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage", 
        "sqs:GetQueueAttributes"
      ]
      Resource = aws_sqs_queue.main_queue.arn
    }]
  })
}

# IAM Role for API Service Account
resource "aws_iam_role" "api_service_role" {
  count = var.enable_irsa ? 1 : 0
  name = "${var.cluster_name}-api-service-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"  
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc[0].arn
      }
      Condition = {
        StringEquals = {
          # Only allow the API service account to assume this role
          "${replace(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:healthmetrics:api-service-account"
        }
      }
    }]
  })

  tags = var.tags
}

# SQS Policy for API (send messages)
resource "aws_iam_role_policy" "api_sqs_policy" {
  count = var.enable_irsa ? 1 : 0
  name = "api-sqs-policy"
  role = aws_iam_role.api_service_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "sqs:SendMessage",
        "sqs:GetQueueAttributes"
      ]
      Resource = aws_sqs_queue.main_queue.arn
    }]
  })
}
