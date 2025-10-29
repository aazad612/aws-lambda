variable "project_prefix" {
  description = "Name/tag prefix applied to resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "num_azs" {
  description = "Number of AZs to use (2-3 typical)"
  type        = number
}

variable "az_names" {
  description = "Optional explicit AZ names; if empty, first num_azs available AZs are used"
  type        = list(string)
}

variable "nat_gateway_strategy" {
  description = "NAT strategy: 'single' (cost saving) or 'one_per_az' (HA)"
  type        = string
  default     = "single"
  validation {
    condition     = contains(["single", "one_per_az"], var.nat_gateway_strategy)
    error_message = "nat_gateway_strategy must be 'single' or 'one_per_az'."
  }
}

variable "enable_s3_endpoint" {
  description = "Create Gateway VPC Endpoint for S3 on private route tables"
  type        = bool
  default     = true
}

variable "enable_dynamodb_endpoint" {
  description = "Create Gateway VPC Endpoint for DynamoDB on private route tables"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention for VPC Flow Logs log group"
  type        = number
  default     = 14
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}
