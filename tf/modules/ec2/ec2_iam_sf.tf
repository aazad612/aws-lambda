# modules/ec2/ec2_iam_sg.tf

locals {
  ec2_tags     = merge({ Project = var.project_prefix, Component = "worker" }, var.tags)
  aurora_is_pg = substr(var.aurora_engine, 0, 16) == "aurora-postgres"
  aurora_port  = var.aurora_is_pg ? 5432 : 3306
}

resource "aws_security_group" "worker_sg" {
  name        = "${var.project_prefix}-worker-sg"
  description = "EC2 worker access"
  vpc_id      = var.vpc_id
  tags        = local.ec2_tags
}

resource "aws_security_group_rule" "ssh_ingress" {
  count             = length(var.ssh_allowed_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  security_group_id = aws_security_group.worker_sg.id
  cidr_blocks       = var.ssh_allowed_cidrs
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.worker_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Open Aurora SG to the worker SG
resource "aws_security_group_rule" "aurora_ingress_from_worker" {
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.aurora_port
  to_port                  = local.aurora_port
  security_group_id        = var.aurora_sg_id
  source_security_group_id = aws_security_group.worker_sg.id
}

# IAM for EC2
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
       type = "Service"
        identifiers = ["ec2.amazonaws.com"]
         }
    actions   = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "worker_role" {
  name               = "${var.project_prefix}-worker-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
  tags               = local.ec2_tags
}

resource "aws_iam_role_policy" "worker_inline" {
  name = "${var.project_prefix}-worker-inline"
  role = aws_iam_role.worker_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { "Effect":"Allow", "Action": [
          "logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"
        ], "Resource":"*" },

      { "Effect":"Allow", "Action": ["s3:GetObject","s3:ListBucket"],
        "Resource": [ var.raw_bucket_arn, "${var.raw_bucket_arn}/*" ] },

      { "Effect":"Allow", "Action": ["s3:PutObject","s3:ListBucket"],
        "Resource": [ var.processed_bucket_arn, "${var.processed_bucket_arn}/*" ] },

      { "Effect":"Allow", "Action": [
          "dynamodb:PutItem","dynamodb:UpdateItem","dynamodb:GetItem","dynamodb:DescribeTable"
        ], "Resource": var.ddb_table_arn },

      { "Effect":"Allow", "Action": ["secretsmanager:GetSecretValue"],
        "Resource": var.aurora_secret_arn }
    ]
  })
}

resource "aws_iam_instance_profile" "worker_profile" {
  name = "${var.project_prefix}-worker-profile"
  role = aws_iam_role.worker_role.name
}
