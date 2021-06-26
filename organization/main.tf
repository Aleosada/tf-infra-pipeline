##################################################################################
# CONFIGURATION (for Terraform > 0.12)
##################################################################################

terraform {
  backend "s3" {
    bucket = "infra-tfstate-74077"
    key    = "organizations/sandbox/state.tfplan"
    region = "sa-east-1"
    dynamodb_table = "infra-tfstatelock-74077"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  region = var.region
}

##################################################################################
# PROVIDERS
##################################################################################

data "aws_organizations_organization" "this" {}
