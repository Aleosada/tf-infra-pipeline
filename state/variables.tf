variable "region" {
  type    = string
  default = "sa-east-1"
}

#Bucket variables
variable "aws_bucket_prefix" {
  type    = string
  default = "infra-tfstate"
}

variable "aws_dynamodb_table" {
  type    = string
  default = "infra-tfstatelock"
}

variable "full_access_users" {
  type    = list(string)
  default = []

}

variable "read_only_users" {
  type    = list(string)
  default = []
}
