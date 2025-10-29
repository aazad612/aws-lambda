variable "env" {
  description = "Environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "project_prefix" {
  description = "Tag/Name prefix for all resources"
  type        = string
}

variable "raw_bucket_name" {
  description = "Globally-unique S3 bucket name for raw uploads. Leave blank to auto-generate."
  type        = string
  default     = ""
}

variable "processed_bucket_name" {
  description = "Globally-unique S3 bucket name for processed outputs. Leave blank to auto-generate."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
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

# variable "key_pair_name" {
#   type = string
#   description = "Existing EC2 key pair name for SSH (or leave unused if you rely on SSM)"
# }

