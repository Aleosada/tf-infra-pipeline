#############################################################################
# VARIABLES
#############################################################################

variable "aws_build_logs_bucket_prefix" {
  type    = string
  default = "build-logs"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "state_bucket" {
  type        = string
  description = "Name of bucket for remote state"
}

variable "dynamodb_state_table_name" {
  type        = string
  description = "Name of dynamodb table for remote state locking"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "project_description" {
  type        = string
  description = "Description of the project"
}

variable "repository_id" {
  type        = string
  description = "Id of the repository my-organization/example"
}

variable "main_branch_name" {
  type        = string
  description = "Name of the main branch"
}
