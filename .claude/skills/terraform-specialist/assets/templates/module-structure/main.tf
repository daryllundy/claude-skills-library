# Terraform Module: [module-name]
# Description: [What this module provisions]
# Usage:
#   module "example" {
#     source      = "./modules/[module-name]"
#     environment = "prod"
#     name        = "myapp"
#   }

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -------------------------------------------------------
# Main resources go here
# -------------------------------------------------------
