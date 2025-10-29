# ---- IAM role for Lambda ----
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"
    principals { 
      type = "Service"
      identifiers = ["lambda.amazonaws.com"] 
      }
    actions   = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ingest_notifier_role" {
  name               = "${var.project_prefix}-ingest-notifier-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = { Project = var.project_prefix, Component = "lambda-ingest-notifier" }
}

# Inline least-priv: CloudWatch Logs + DDB write + S3 HEAD
resource "aws_iam_role_policy" "ingest_notifier_inline" {
  name = "${var.project_prefix}-ingest-notifier-inline"
  role = aws_iam_role.ingest_notifier_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect="Allow", Action=[
          "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"
        ], Resource="*" },
      { Effect="Allow", Action=["dynamodb:PutItem","dynamodb:DescribeTable"],
        Resource=aws_dynamodb_table.media_catalog.arn },
      { Effect="Allow", Action=["s3:HeadObject","s3:GetObject","s3:GetBucketLocation"],
        Resource=[
          aws_s3_bucket.raw.arn,
          "${aws_s3_bucket.raw.arn}/*"
        ]}
    ]
  })
}

# ---- Lambda function ----
resource "aws_lambda_function" "ingest_notifier" {
  function_name = "${var.project_prefix}-ingest-notifier"
  role          = aws_iam_role.ingest_notifier_role.arn
  handler       = "ingest_notifier.lambda_handler"
  runtime       = "python3.12"
  filename      = "${path.module}/../lambdas/ingest_notifier.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambdas/ingest_notifier.zip")

  environment {
    variables = {
      DDB_TABLE = aws_dynamodb_table.media_catalog.name
    }
  }

  tags = { Project = var.project_prefix, Component = "lambda-ingest-notifier" }
}

# Allow S3 to invoke this Lambda
resource "aws_lambda_permission" "allow_s3_invoke" {
  statement_id  = "AllowExecutionFromS3RawBucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingest_notifier.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.raw.arn
}

# S3 → Lambda notification (entire bucket; add filters if you want)
# NOTE: Only one aws_s3_bucket_notification per bucket. If you already have one,
# merge this block into it instead of creating another.
resource "aws_s3_bucket_notification" "raw_events" {
  bucket = aws_s3_bucket.raw.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.ingest_notifier.arn
    events              = ["s3:ObjectCreated:*"]
    # optional filters:
    # filter_prefix     = "incoming/"
    # filter_suffix     = ".parquet"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke]
}
