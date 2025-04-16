# Fargate Profile for default namespace (stateless apps)

# Fargate Execution Role
# module "fargate_iam" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#   version = "~> 5.30"

#   role_name = "${var.cluster_name}-fargate-pod-execution"
#   attach_amazon_eks_fargate_pod_execution_role_policy = true

#   oidc_providers = {
#     main = {
#       provider_arn               = module.eks.oidc_provider_arn
#       namespace_service_accounts = ["default:*", "kube-system:*", "monitoring:*"]
#     }
#   }
# }



# resource "aws_eks_fargate_profile" "fargate_profile_default" {
#   fargate_profile_name         = "default-fp"
#   cluster_name                 = module.eks.cluster_name
#   subnet_ids                   = module.vpc.private_subnets

#   selector {
#     namespace = "default"
#   }

#   selector {
#     namespace = "kube-system"
#     labels = {
#       k8s-app = "kube-dns"
#     }
#   }


#   # Using the IAM role created by the module above
#   # pod_execution_role_name = module.fargate_iam.iam_role_name
#   pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn

#   timeouts {
#     create = "30m"
#     delete = "30m"
#   }

#   tags = merge(
#     local.default_tags,        # Global tags
#     {
#       Component = "fargate-profile"
#       ProfileType = "default"
#     }
#   )
# }



# resource "aws_eks_fargate_profile" "fargate_profile_monitoring" {
#   fargate_profile_name         = "monitoring-fp"
#   cluster_name                 = module.eks.cluster_name
#   subnet_ids                   = module.vpc.private_subnets

#   selector {
#     namespace = "monitoring"
#   }

#   # Using the IAM role created by the module above
#   # pod_execution_role_name = module.fargate_iam.iam_role_name
#   pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn

#   timeouts {
#     create = "30m"
#     delete = "30m"
#   }

#   tags = merge(
#     local.default_tags,        # Global tags
#     {
#       Component = "fargate-profile"
#       ProfileType = "monitoring"
#     }
#   )
# }



# Default Fargate Profile 
module "fargate_profile_default" {
  source  = "terraform-aws-modules/eks/aws//modules/fargate-profile"
  version = "~> 20.0"

  name         = "default-fp"
  cluster_name = module.eks.cluster_name
  subnet_ids   = module.vpc.private_subnets

  selectors = [
    {
      namespace = "default"
    },
    {
      namespace = "kube-system"
      labels = {
        k8s-app = "kube-dns"
      }
    }
  ]

  # Using the IAM role created by the module above
  # pod_execution_role_name = module.fargate_iam.iam_role_name
  iam_role_name = aws_iam_role.fargate_pod_execution_role.name

  timeouts = {
    create = "30m"
    delete = "30m"
  }

  tags = merge(
    local.default_tags,        # Global tags
    {
      Component = "fargate-profile"
      ProfileType = "default"
    }
  )
}

# # Monitoring Fargate Profile (using module)
module "fargate_profile_monitoring" {
  source  = "terraform-aws-modules/eks/aws//modules/fargate-profile"
  version = "~> 20.0"

  name         = "monitoring-fp"
  cluster_name = module.eks.cluster_name
  subnet_ids   = module.vpc.private_subnets

  selectors = [
    {
      namespace = "monitoring"
    }
  ]

  # pod_execution_role_arn = module.fargate_iam.iam_role_arn
  iam_role_name = aws_iam_role.fargate_pod_execution_role.name

  timeouts = {
    create = "30m"
    delete = "30m"
  }

  tags = merge(
    local.default_tags,       # Global tags
    {
      Component = "fargate-profile"
      ProfileType = "monitoring"
    }
  )
}