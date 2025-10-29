terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}


#   default_tags {
#     tags = {
#       Environment  = "prod"
#       Project      = "media-intake"
#       Application  = "asset-processor"
#       Owner        = "data-platform@company.com"
#       Team         = "Data Engineering"
#       CostCenter   = "CC-4721"
#       BusinessUnit = "Media"
#       Compliance   = "HIPAA"
#       Terraform    = "true"
#       CreatedBy    = "terraform"
#     }
#   }
# tags = { Name = "${var.project_prefix}-rds" }  # merges with defaults