locals {
  common_tags = merge(
    { Project = var.project_prefix, Environment = var.env },
    var.tags
  )

  raw_bucket_name = (
    var.raw_bucket_name != "" ?
    var.raw_bucket_name :
    "${var.project_prefix}-raw-${random_id.suffix.hex}"
  )

  processed_bucket_name = (
    var.processed_bucket_name != "" ?
    var.processed_bucket_name :
    "${var.project_prefix}-processed-${random_id.suffix.hex}"
  )
}

resource "random_id" "suffix" {
  byte_length = 3
}


# RAW BUCKET
resource "aws_s3_bucket" "raw" {
  bucket        = local.raw_bucket_name
  force_destroy = false
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "raw" {
  bucket                  = aws_s3_bucket.raw.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# PROCESSED BUCKET
resource "aws_s3_bucket" "processed" {
  bucket        = local.processed_bucket_name
  force_destroy = false
  tags          = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "processed" {
  bucket                  = aws_s3_bucket.processed.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "processed" {
  bucket = aws_s3_bucket.processed.id
  versioning_configuration { status = "Enabled" }
}


# Basic lifecycle for processed outputs: IA at 30d, Glacier IR at 180d, expire noncurrent after 30d
resource "aws_s3_bucket_lifecycle_configuration" "processed" {
  bucket = aws_s3_bucket.processed.id

  rule {
    id     = "tiering-processed"
    status = "Enabled"
    filter {}
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 180
      storage_class = "GLACIER_IR"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


