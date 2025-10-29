module "networking" {
  source               = "./modules/networking"
  project_prefix       = var.project_prefix
  vpc_cidr             = var.vpc_cidr
  num_azs              = var.num_azs
  az_names             = var.az_names
  nat_gateway_strategy = var.nat_gateway_strategy

  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true
  enable_flow_logs         = true
  flow_logs_retention_days = 14

  tags = {
    Environment = "dev"
    Owner       = "platform"
  }
}

