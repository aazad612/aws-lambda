variable "project_prefix" {
     type = string 
     }
variable "vpc_id" { 
    type = string
     }
variable "private_subnet_ids" {
     type = list(string) 
     } 
     
variable "rds_allowed_sg_ids" {
  type    = list(string)
  default = []
}
variable "rds_allowed_cidr_blocks" {
  type    = list(string)
  default = ["174.238.167.212/32"]
}


variable "aurora_engine" {
  type    = string
  default = "aurora-postgresql"
}
variable "aurora_engine_version" {
  type    = string
  default = "15.4"
}

variable "aurora_cluster_identifier" {
  type    = string
  default = "media-intake-aurora"
}
variable "db_name" {
  type    = string
  default = "appdb"
}
variable "db_username" {
  type    = string
  default = "appadmin"
}

variable "aurora_min_acus" {
  type    = number
  default = 2
} 

variable "aurora_max_acus" {
  type    = number
  default = 16
} 

variable "backup_retention_days" {
  type    = number
  default = 7
}
variable "deletion_protection" {
  type    = bool
  default = true
}
variable "enable_performance_insights" {
  type    = bool
  default = true
}
variable "enable_data_api" {
  type    = bool
  default = true
} 


variable "tags" {
  type    = map(string)
  default = {}
}
