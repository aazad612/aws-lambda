output "worker_instance_id" { value = aws_instance.worker.id }
output "worker_private_ip"  { value = aws_instance.worker.private_ip }
output "worker_sg_id"       { value = aws_security_group.worker_sg.id }
