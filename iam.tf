# Fargate Execution Role
# resource "aws_iam_role" "fargate_pod_execution_role" {
#   name = "${var.cluster_name}-fargate-execution-role"

#   assume_role_policy = jsonencode({
#     Statement = [{
#       Action = "sts:AssumeRole"
#       Effect = "Allow"
#       Principal = {
#         Service = "eks-fargate-pods.amazonaws.com"
#       }
#     }]
#     Version = "2012-10-17"
#   })
# }

# resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
#   role       = aws_iam_role.fargate_pod_execution_role.name
# }

# resource "aws_iam_role" "fargate_pod_execution_role" {
#   name = "${var.cluster_name}-fargate-pod-execution"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Federated = module.eks.oidc_provider_arn
#         }
#         Action = "sts:AssumeRoleWithWebIdentity"
#         Condition = {
#           StringLike = {
#             "${replace(module.eks.oidc_provider_arn, "arn:aws:iam::", "oidc.eks.")}:sub" = [
#               "system:serviceaccount/default:*",
#               "system:serviceaccount/kube-system:*",
#               "system:serviceaccount/monitoring:*"
#             ]
#           }
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "fargate_pod_execution_attachment" {
#   role       = aws_iam_role.fargate_pod_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
# }


resource "aws_iam_role" "fargate_pod_execution_role" {
  name = "${var.cluster_name}-fargate-pod-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution_role-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

#  Custom inline policies using new resource
resource "aws_iam_role_policy" "fargate_additional_policy" {
  name = "${var.cluster_name}-fargate-additional-policy"
  role = aws_iam_role.fargate_pod_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# # Ensuring Terraform exclusively manages all inline policies
# resource "aws_iam_role_policy_exclusive" "fargate_policy_exclusive" {
#   role_name = aws_iam_role.fargate_pod_execution_role.name
  
#   # Explicitly listing all inline policies that should be managed
#   policy_names = [
#     aws_iam_role_policy.fargate_additional_policy.name
#   ]
# }

# EBS CSI Driver IAM Role (IRSA)
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.cluster_name}-ebs-csi-driver"
  
  # Attaches the AWS-managed EBS CSI policy
  attach_ebs_csi_policy = true

  # Links to EKS OIDC provider
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = merge(
    local.default_tags
  )
}