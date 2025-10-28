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
