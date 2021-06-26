##################################################################################
# OUTPUT
##################################################################################

output "devops_account_id" {
  value = aws_organizations_account.devops-account.id
}

output "development_account_id" {
  value = aws_organizations_account.development-account.id
}

output "uat_account_id" {
  value = aws_organizations_account.uat-account.id
}

output "production_account_id" {
  value = aws_organizations_account.production-account.id
}
