module "rds" {
  source                    = "./modules/rds"
  project_prefix            = "media-intake"
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  rds_allowed_sg_ids        = [] # we’ll add EC2 SG in Batch 3
  aurora_cluster_identifier = "media-intake-aurora"
}