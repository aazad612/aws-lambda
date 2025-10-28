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
