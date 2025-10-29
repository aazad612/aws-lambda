

locals {
  tags         = merge({ Project = var.project_prefix, Component = "database" }, var.tags)
  is_pg        = var.aurora_engine == "aurora-postgresql"
  pg_family    = "aurora-postgresql15" # adjust if you change version family
  mysql_family = "aurora-mysql8.0"
}


resource "aws_security_group" "aurora_sg" {
  name        = "${var.aurora_cluster_identifier}-sg"
  description = "Aurora access"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

# Allow from allowed SGs
resource "aws_security_group_rule" "in_from_sg" {
  for_each                 = toset(var.rds_allowed_sg_ids)
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = local.is_pg ? 5432 : 3306
  to_port                  = local.is_pg ? 5432 : 3306
  security_group_id        = aws_security_group.aurora_sg.id
  source_security_group_id = each.value
}

# Optional: allow specific CIDRs (use sparingly)
resource "aws_security_group_rule" "in_from_cidr" {
  count             = length(var.rds_allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  protocol          = "tcp"
  from_port         = local.is_pg ? 5432 : 3306
  to_port           = local.is_pg ? 5432 : 3306
  security_group_id = aws_security_group.aurora_sg.id
  cidr_blocks       = var.rds_allowed_cidr_blocks
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  security_group_id = aws_security_group.aurora_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ---------------- Subnet Group ----------------
resource "aws_db_subnet_group" "aurora_subnets" {
  name       = "${var.aurora_cluster_identifier}-subnets"
  subnet_ids = var.private_subnet_ids
  tags       = local.tags
}

# ---------------- Secrets Manager (master password) ----------------
resource "random_password" "db_master_password" {
  length  = 24
  special = true
}

resource "aws_secretsmanager_secret" "master" {
  name = "${var.aurora_cluster_identifier}-master"
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "master_v" {
  secret_id     = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({ password = random_password.db_master_password.result })
}

# ---------------- Cluster Parameter Group (optional tuning) ----------------
resource "aws_rds_cluster_parameter_group" "cluster_params" {
  name        = "${var.aurora_cluster_identifier}-params"
  family      = local.is_pg ? local.pg_family : local.mysql_family
  description = "Aurora cluster parameters"
  tags        = local.tags

  # Example tuning (Postgres)
  parameter {
    name  = "log_min_duration_statement"
    value = "2000" # ms
  }
}

# ---------------- Aurora Serverless v2 Cluster ----------------
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = var.aurora_cluster_identifier
  engine             = var.aurora_engine
  engine_version     = var.aurora_engine_version

  database_name   = var.db_name
  master_username = var.db_username
  master_password = random_password.db_master_password.result

  db_subnet_group_name   = aws_db_subnet_group.aurora_subnets.name
  vpc_security_group_ids = [aws_security_group.aurora_sg.id]

  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "06:15-06:45"
  preferred_maintenance_window = "sun:07:00-sun:08:00"

  storage_encrypted     = true
  copy_tags_to_snapshot = true
  deletion_protection   = var.deletion_protection

  iam_database_authentication_enabled = true
  enable_http_endpoint                = var.enable_data_api # Data API

  # Serverless v2 scaling
  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_acus
    max_capacity = var.aurora_max_acus
  }

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.cluster_params.name
  tags                            = local.tags

  depends_on = [aws_secretsmanager_secret_version.master_v]
}

# ---------------- At least one instance (writer) ----------------
resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.aurora_cluster_identifier}-writer-1"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = var.aurora_engine
  engine_version     = var.aurora_engine_version

  performance_insights_enabled = var.enable_performance_insights
  publicly_accessible          = true
  tags                         = local.tags
}


# resource "aws_security_group_rule" "aurora_from_home" {
#   type              = "ingress"
#   protocol          = "tcp"
#   from_port         = 5432
#   to_port           = 5432
#   security_group_id = aws_security_group.aurora_sg.id
#   cidr_blocks       = ["174.238.167.212/32"]   # not 0.0.0.0/0
# }


