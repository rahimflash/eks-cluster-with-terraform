variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "eks-project"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]
}

variable "public_subnets" {
  description = "Public subnets"
  type        = list(string)
  default     = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {
    Terraform   = "true"
    DeploymentMethod = "terraform"
  }
}

variable "default_labels" {
  description = "Default Kubernetes labels for all node groups"
  type        = map(string)
  default     = {
    Terraform   = "true"
  }
}

variable "bucket_prefix" {
  description = "Prefix for S3 state bucket"
  type        = string
  default     = "terraform-state"
}

variable "fargate_profile_name" {
  description = "Fargate profile name"
  type        = string
  default     = "default-fp"

}