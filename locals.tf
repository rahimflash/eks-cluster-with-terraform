locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = var.aws_region
  env        = var.environment
  bucket_name = "${var.bucket_prefix}-${local.account_id}" 

  default_tags = merge(
    var.tags,
    {
      # These will merge with/override var.tags
      Environment     = var.environment
      Project         = var.project_name
      ManagedBy       = "Terraform"
      LastDeployment  = timestamp()
    }
  )
}