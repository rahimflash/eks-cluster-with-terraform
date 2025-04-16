# Managed Node Group for stateful workloads
locals {
  node_group_defaults = {
    # Infrastructure Configuration
    ami_type                   = "AL2_x86_64"
    disk_size                  = 50
    iam_role_attach_cni_policy = true
    enable_monitoring          = true
    
    # Scaling Configuration
    min_size     = 1
    max_size     = 3
    desired_size = 2


    # Common IAM Policies
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }
}

# General Purpose Node Group
module "general_workers" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.0"

  # Basic Identification
  cluster_name    = module.eks.cluster_name
  name  = "general-workers"
  subnet_ids      = module.vpc.private_subnets

  # Instance Configuration
  instance_types = ["t3.small"]
#  capacity_type  = "ON_DEMAND"  # Explicitly declare capacity type

  # Inherit and override defaults
  ami_type       = local.node_group_defaults.ami_type
  disk_size      = local.node_group_defaults.disk_size
  min_size       = local.node_group_defaults.min_size
  max_size       = local.node_group_defaults.max_size
  desired_size   = local.node_group_defaults.desired_size

  # IAM Configuration
  enable_monitoring = local.node_group_defaults.enable_monitoring
  iam_role_attach_cni_policy = local.node_group_defaults.iam_role_attach_cni_policy
  iam_role_additional_policies = local.node_group_defaults.iam_role_additional_policies

  # Kubernetes Labels
  labels = merge(
    {
      "workload-type"           = "general"
      "node.lifecycle"          = "on-demand"
      "node.kubernetes.io/role" = "general"
    },
    var.default_labels
  )

  # Tags
  tags = merge(
    local.default_tags,
    {
      "k8s.io/cluster-autoscaler/enabled"             = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      Component                                       = "node-group"
      NodeFamily                                      = "general-purpose"
    }
  )
}

# GPU Node Group
module "gpu_workers" {
  source  = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version = "~> 19.0"

  # Basic Identification
  cluster_name    = module.eks.cluster_name
  name  = "gpu-workers"
  subnet_ids      = module.vpc.private_subnets

  # Instance Configuration
  ami_type       = "AL2_x86_64_GPU"
  instance_types = ["g4dn.xlarge"]
  disk_size      = 100
  # capacity_type  = "ON_DEMAND"

  # Scaling Configuration
  min_size     = 0  # Scale to 0 when not needed
  max_size     = 2
  desired_size = 0

  # IAM Configuration (inherit from defaults)
  enable_monitoring = local.node_group_defaults.enable_monitoring
  iam_role_attach_cni_policy = local.node_group_defaults.iam_role_attach_cni_policy
  iam_role_additional_policies = local.node_group_defaults.iam_role_additional_policies

  # Kubernetes Labels and Taints
  labels = merge(
    {
      "workload-type"           = "gpu"
      "node.lifecycle"          = "on-demand"
      "node.kubernetes.io/role" = "gpu"
    },
    var.default_labels
  )

  taints = {
    gpu = {
      key    = "nvidia.com/gpu"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }

  # Tags
  tags = merge(
    local.default_tags,
    {
      "k8s.io/cluster-autoscaler/enabled"             = "true"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      Component                                       = "node-group"
      NodeFamily                                      = "gpu"
    }
  )
}