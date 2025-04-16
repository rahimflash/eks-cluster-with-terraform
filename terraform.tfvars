aws_region     = "eu-west-1"
cluster_name   = "prod-eks-cluster"
cluster_version = "1.32"
environment    = "production"
project_name   = "core-platform"
bucket_prefix = "sandbox-tfstate"

vpc_cidr = "10.0.0.0/16"

# azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

private_subnets = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
public_subnets  = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]

tags = {
  Project     = "eks-cluster"
  Owner       = "gilbert@devops"
  DeploymentMethod = "terraform"
}