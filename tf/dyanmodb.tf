resource "aws_dynamodb_table" "media_catalog" {
  name         = "${var.project_prefix}-MediaCatalog"
  billing_mode = "PAY_PER_REQUEST"

  # Primary key: assetId (UUID you assign in app/worker)
  hash_key = "assetId"
  attribute {
    name = "assetId"
    type = "S"
  }

  # Optional GSI to query by ingest date (YYYY-MM-DD) if you want day-based listings quickly
  global_secondary_index {
    name               = "gsi_ingestDate"
    hash_key           = "ingestDate"
    projection_type    = "INCLUDE"
    non_key_attributes = ["bucket", "rawKey", "processedKey", "sizeBytes", "contentType", "status"]
  }
  attribute {
    name = "ingestDate"
    type = "S"
  }

  point_in_time_recovery { enabled = true }
}

