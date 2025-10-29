########################################
# AWS Secrets Manager for Aurora Master Password
########################################

# Random secure password
resource "random_password" "aurora_master" {
  length  = 20
  special = true
}

# The secret container (metadata)
resource "aws_secretsmanager_secret" "master" {
  name                    = "${var.project_prefix}-aurora-master"
  description             = "Aurora DB master credentials for ${var.project_prefix}"
  recovery_window_in_days = 0
  tags = merge(var.tags, {
    Name = "${var.project_prefix}-aurora-secret"
  })
}

# Secret value version (actual password JSON)
resource "aws_secretsmanager_secret_version" "master_value" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    username = "appadmin"
    password = random_password.aurora_master.result
  })
}

# Output for re-use
output "aurora_master_secret_arn" {
  value       = aws_secretsmanager_secret.master.arn
  description = "Secrets Manager ARN for Aurora master credentials"
}
