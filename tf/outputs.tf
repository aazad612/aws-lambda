output "raw_bucket_name" {
  value       = aws_s3_bucket.raw.bucket
  description = "Raw uploads bucket"
}

output "processed_bucket_name" {
  value       = aws_s3_bucket.processed.bucket
  description = "Processed outputs bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.media_catalog.name
  description = "MediaCatalog table name"
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "aurora_cluster_endpoint" {
  value = module.rds.aurora_cluster_endpoint
}

output "aurora_password" {
  value = module.rds.aurora_password
  sensitive = true
}