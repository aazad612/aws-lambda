# modules/ec2/variables.tf

variable "project_prefix"     { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
# variable "key_pair_name"      { type = string }
variable "instance_type"      { 
  type = string 
 default = "t3.small" 
 }

# Networking / Security
variable "ssh_allowed_cidrs"  {
   type = list(string)
    default = [] 
    }

# ---- RDS (Aurora) inputs ----
variable "aurora_engine"        { type = string }  # e.g. "aurora-postgresql" or "aurora-mysql"
variable "aurora_sg_id"         { type = string }  # SG id of the Aurora cluster
variable "aurora_endpoint"      { type = string }  # writer endpoint hostname
variable "aurora_db_name"       { type = string }  # e.g. "appdb"
variable "aurora_db_user"       { type = string }  # e.g. "appadmin"
variable "aurora_secret_arn"    { type = string }  # Secrets Manager ARN for master creds

# ---- S3 & DynamoDB inputs ----
variable "raw_bucket_name"      { type = string }
variable "raw_bucket_arn"       { type = string }
variable "processed_bucket_name"{ type = string }
variable "processed_bucket_arn" { type = string }

variable "ddb_table_name"       { type = string }
variable "ddb_table_arn"        { type = string }

variable "tags"                 { 
  type = map(string)
   default = {} 
   }

variable "aurora_is_pg" {
  type = bool
  default = true
  
}