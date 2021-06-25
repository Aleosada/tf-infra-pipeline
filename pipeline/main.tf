##################################################################################
# CONFIGURATION (for Terraform > 0.12)
##################################################################################

terraform {
  backend "s3" {
    bucket = "infra-tfstate-27991"
    key    = "pipelines/resource/state.tfplan"
    region = "us-east-1"
    dynamodb_table = "infra-tfstatelock-27991"
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

#############################################################################
# DATA SOURCES
#############################################################################

data "aws_s3_bucket" "state_bucket" {
  bucket = var.state_bucket
}

data "aws_dynamodb_table" "state_table" {
  name = var.dynamodb_state_table_name
}
