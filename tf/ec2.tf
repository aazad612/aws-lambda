module "ec2_worker" {
  source = "./modules/ec2"

  project_prefix     = var.project_prefix
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  instance_type      = "t3.small"

  # RDS (from your Aurora resources/outputs)
  aurora_engine     = module.rds.aurora_engine
  aurora_sg_id      = module.rds.aurora_sg_id
  aurora_endpoint   = module.rds.aurora_reader_endpoint
  aurora_db_name    = module.rds.aurora_db_name
  aurora_db_user    = module.rds.aurora_user
  aurora_secret_arn = aws_secretsmanager_secret.master.arn

  # S3 & DynamoDB (root resources)
  raw_bucket_name       = aws_s3_bucket.raw.bucket
  raw_bucket_arn        = aws_s3_bucket.raw.arn
  processed_bucket_name = aws_s3_bucket.processed.bucket
  processed_bucket_arn  = aws_s3_bucket.processed.arn

  ddb_table_name = aws_dynamodb_table.media_catalog.name
  ddb_table_arn  = aws_dynamodb_table.media_catalog.arn

  # Optional SSH
  ssh_allowed_cidrs = ["0.0.0.0/0"]

  tags = {
    Environment = "dev"
  }
}
