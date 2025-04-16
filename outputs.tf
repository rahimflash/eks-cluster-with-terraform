output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_iam_role_name" {
  description = "IAM role name of the EKS cluster"
  value       = module.eks.cluster_iam_role_name
}

# Node Group Outputs

output "node_groups" {
  description = "Map of all node groups created and their attributes"
  value = {
    general_workers = module.general_workers
    gpu_workers    = module.gpu_workers
  }
}

output "node_group_iam_role_arns" {
  description = "IAM role ARNs for the node groups"
  value = {
    general_workers = module.general_workers.iam_role_arn
    gpu_workers    = module.gpu_workers.iam_role_arn
  }
}

output "node_group_arns" {
  description = "ARNs of the managed node groups"
  value = {
    general_workers = module.general_workers.node_group_arn
    gpu_workers    = module.gpu_workers.node_group_arn
  }
}

output "node_group_ids" {
  description = "IDs of the managed node groups"
  value = {
    general_workers = module.general_workers.node_group_id
    gpu_workers    = module.gpu_workers.node_group_id
  }
}

output "node_group_resources" {
  description = "Map of node group resources (autoscaling groups, etc.)"
  value = {
    general_workers = module.general_workers.node_group_resources
    gpu_workers    = module.gpu_workers.node_group_resources
  }
}

output "node_group_status" {
  description = "Status of the node groups"
  value = {
    general_workers = module.general_workers.node_group_status
    gpu_workers    = module.gpu_workers.node_group_status
  }
}


# output "node_group_roles" {
#   description = "ARNs of all node group IAM roles"
#   value = compact([
#     module.general_workers.iam_role_arn,
#     module.gpu_workers.iam_role_arn
#   ])
# }

# output "node_group_details" {
#   description = "Detailed information about general node groups"
#   value = {
#     general = {
#       arn            = module.general_workers.iam_role_arn
#       min_size       = local.node_group_defaults.min_size
#       max_size       = local.node_group_defaults.max_size
#       desired_size   = local.node_group_defaults.desired_size
#       instance_types = local.node_group_defaults.instance_types
#     }
#   }
# }
# output "node_group_details_gpu" {
#   description = "Detailed information about gpu node groups"
#   value = {
#     gpu = {
#       arn            = module.gpu_workers.iam_role_arn
#       min_size       = local.node_group_defaults.min_size
#       max_size       = local.node_group_defaults.max_size
#       desired_size   = local.node_group_defaults.desired_size
#       instance_types = local.node_group_defaults.instance_types_gpu
#     }
#   }
# }


# output "node_group_roles" {
#   description = "ARNs of all node group IAM roles"
#   value = concat(
#     # For default node group
#     [for ng in module.general_workers : ng.iam_role_arn],
#     # For GPU node group (if created)
#     try([for ng in module.gpu_workers : ng.iam_role_arn], [])
#   )
# }

# output "node_group_details" {
#   description = "Detailed information about all node groups"
#   value = {
#     default = {
#       for ng in module.general_workers :
#       ng.node_group_name => {
#         arn         = ng.iam_role_arn
#         min_size    = ng.min_size
#         max_size    = ng.max_size
#         desired_size = ng.desired_size
#         instance_types = ng.instance_types
#       }
#     }
#     gpu = {
#       for ng in try(module.gpu_workers, []) :
#       ng.node_group_name => {
#         arn         = ng.iam_role_arn
#         min_size    = ng.min_size
#         max_size    = ng.max_size
#         desired_size = ng.desired_size
#         instance_types = ng.instance_types
#       }
#     }
#   }
# }

# Fargate Outputs
# output "fargate_profile_names" {
#   description = "Names of all Fargate profiles"
#   value = [
#     module.fargate_profile_default.fargate_profile_name,
#     module.fargate_profile_monitoring.fargate_profile_name
#   ]
# }

# output "fargate_profile_name" {
#   description = "ARNs of all Fargate profiles"
#   value = [
#     aws_eks_fargate_profile.fargate_profile_default.fargate_profile_name,
#     aws_eks_fargate_profile.fargate_profile_monitoring.fargate_profile_name
#   ]
# }

output "configure_kubectl" {
  description = "Configure kubectl command"
  value       = "aws eks --region ${var.aws_region} update-kubeconfig --name ${module.eks.cluster_name}"
}

output "fargate_profile_arns" {
  description = "ARNs of all Fargate profiles"
  value = [
    module.fargate_profile_default.fargate_profile_arn,
    module.fargate_profile_monitoring.fargate_profile_arn
  ]
}

# output "fargate_pod_execution_role_arn" {
#   description = "ARN of the Fargate pod execution IAM role"
#   value       = module.fargate_pod_execution_role.iam_role_arn
# }
output "fargate_pod_execution_role_arn" {
  description = "ARN of the IAM role used for Fargate pod execution"
  value       = aws_iam_role.fargate_pod_execution_role.arn
}

output "fargate_pod_execution_role_name" {
  description = "Name of the IAM role used for Fargate pod execution"
  value       = aws_iam_role.fargate_pod_execution_role.name
}