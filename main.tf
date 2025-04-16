# main.tf
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }

  # Initial local backend (will be reconfigured)
  backend "local" {
    path = "temp-state/terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region

}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        module.eks.cluster_name
      ]
    }
  }
}

module "tf_state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket = local.bucket_name
  acl    = null

  # Security settings
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  force_destroy           = false  # Prevents accidental deletion

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = merge(
    local.default_tags,
    {
      Name        = "Terraform State Bucket"
      Description = "Stores remote state for EKS cluster"
    }
  )

  # Example policy for team access
  # attach_policy = true
  # policy = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [
  #     {
  #       Effect = "Allow"
  #       Principal = {
  #         AWS = [
  #           "arn:aws:iam::${local.account_id}:user/terraform-user",
  #           "arn:aws:iam::${local.account_id}:role/ci-cd-role"
  #         ]
  #       }
  #       Action = [
  #         "s3:GetObject",
  #         "s3:PutObject",
  #         "s3:DeleteObject"
  #       ]
  #       Resource = [
  #         "${module.tf_state_bucket.s3_bucket_arn}/env:/${local.env}/*"
  #       ]
  #     }
  #   ]
  # })

}

resource "terraform_data" "reconfigure_backend" {
  triggers_replace = [
    module.tf_state_bucket.s3_bucket_id
  ]

  # provisioner "local-exec" {
  #   command = <<EOF
  #   terraform init -reconfigure \
  #     -backend-config="bucket=${module.tf_state_bucket.s3_bucket_id}" \
  #     -backend-config="key=eks-cluster/terraform.tfstate" \
  #     -backend-config="region=${var.aws_region}" \
  #     -backend-config="encrypt=true" \
  #     -backend-config="use_lockfile=true"      
  #   EOF
  # }
  depends_on = [module.tf_state_bucket]

  provisioner "local-exec" {
    command = <<EOT
      cat > backend.tf <<EOF
      terraform {
        backend "s3" {
          bucket         = "${module.tf_state_bucket.s3_bucket_id}"
          key            = "eks-cluster/terraform.tfstate"
          region         = "${var.aws_region}"
          encrypt        = true
          use_lockfile   = true
        }
      }
      EOF
      terraform init -migrate-state -force-copy
    EOT
  }

}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  depends_on = [terraform_data.reconfigure_backend] 

#  azs             = var.azs
  azs = data.aws_availability_zones.available.names
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = merge(
    local.default_tags,
    {
      "kubernetes.io/role/elb" = "1"
    }
  )

  private_subnet_tags = merge(
    local.default_tags,
    {
      "kubernetes.io/role/internal-elb" = "1"
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    }
  )
}


module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  create_iam_role = true
  iam_role_name   = "${var.cluster_name}-cluster-role"
  iam_role_additional_policies = {
    AmazonEBSCSIDriverPolicy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn
    }
  }


  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_https = {
      description = "Allow pods to communicate with EKS control plane"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  tags = merge(
    local.default_tags,
    {
      Component = "eks-control-plane"
    }
  )
}

# data "aws_iam_role" "eks_cluster_role" {
#   name = module.eks.cluster_iam_role_name
# }

# # Exclusive policy management for the EKS cluster role
# resource "aws_iam_role_policy_exclusive" "eks_cluster_role_policy_exclusive" {
#   role_name = local.eks_cluster_role_name
  
#   policy_names = [
#     # All managed policy names that should be attached to this role
#     "AmazonEBSCSIDriverPolicy"
#   ]
#   depends_on = [module.eks]

# }