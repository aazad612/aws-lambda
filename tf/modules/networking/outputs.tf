output "vpc_id" {
  value       = aws_vpc.this.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = [for s in aws_subnet.public  : s.id]
  description = "Public subnet IDs (index corresponds to AZ index)"
}

output "private_subnet_ids" {
  value       = [for s in aws_subnet.private : s.id]
  description = "Private subnet IDs (index corresponds to AZ index)"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public route table ID"
}

output "private_route_table_ids" {
  value       = [for rt in aws_route_table.private : rt.id]
  description = "Private route table IDs"
}

output "nat_gateway_ids" {
  value       = [for n in aws_nat_gateway.nat : n.id]
  description = "NAT Gateway IDs"
}

output "s3_vpc_endpoint_id" {
  value       = try(aws_vpc_endpoint.s3[0].id, null)
  description = "S3 Gateway VPC Endpoint ID (null if disabled)"
}

output "dynamodb_vpc_endpoint_id" {
  value       = try(aws_vpc_endpoint.dynamodb[0].id, null)
  description = "DynamoDB Gateway VPC Endpoint ID (null if disabled)"
}
