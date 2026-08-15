module "network" {
  source = "../../modules/network"

  vpc_cidr    = var.vpc_cidr
  environment = var.environment
  aws_region  = var.aws_region
}

module "identity" {
  source = "../../modules/identity"

  environment               = var.environment
  data_lake_bucket_arn      = var.data_lake_bucket_arn
  data_lake_prefix          = var.data_lake_prefix
  assume_role_services      = var.assume_role_services
  control_plane_trusted_arn = var.control_plane_trusted_arn
}
