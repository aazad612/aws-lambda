output "aurora_cluster_arn" {
  value = aws_rds_cluster.aurora.arn
}
output "aurora_cluster_endpoint" {
  value       = aws_rds_cluster.aurora.endpoint
  description = "Writer endpoint"
}
output "aurora_reader_endpoint" {
  value       = aws_rds_cluster.aurora.reader_endpoint
  description = "Reader endpoint"
}
output "aurora_sg_id" {
  value       = aws_security_group.aurora_sg.id
  description = "Aurora security group"
}
output "aurora_subnet_group" {
  value = aws_db_subnet_group.aurora_subnets.name
}
output "aurora_master_secret_arn" {
  value       = aws_secretsmanager_secret.master.arn
  description = "Secrets Manager secret for master password"
}
output "aurora_db_name" {
  value = var.db_name
}

output "aurora_user" {
  value = var.db_username
}

output "aurora_engine"{
  value = var.aurora_engine
}

output "aurora_password" {
  value = random_password.db_master_password
}