##################################################################################
# RESOURCES
##################################################################################

resource "aws_organizations_organizational_unit" "parent" {
  name      = var.organizational_unit_name
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_account" "devops-account" {
  name  = "DevOps"
  email = var.devops_account_email
  parent_id = aws_organizations_organizational_unit.parent.id
}

resource "aws_organizations_account" "development-account" {
  name  = "Development"
  email = var.development_account_email
  parent_id = aws_organizations_organizational_unit.parent.id
}

resource "aws_organizations_account" "uat-account" {
  name  = "UAT"
  email = var.uat_account_email
  parent_id = aws_organizations_organizational_unit.parent.id
}

resource "aws_organizations_account" "production-account" {
  name  = "Production"
  email = var.production_account_email
  parent_id = aws_organizations_organizational_unit.parent.id
}

resource "aws_iam_policy" "devops-assume-role-policy" {
  name        = "${var.organizational_unit_name}DevOpsAssumeRolePolicy"
  description = "Assume role for ${var.organizational_unit_name} devops account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${aws_organizations_account.devops-account.id}:role/OrganizationAccountAccessRole"
      }
    ]
  })
}

resource "aws_iam_policy" "development-assume-role-policy" {
  name        = "${var.organizational_unit_name}DevelopmentAssumeRolePolicy"
  description = "Assume role for ${var.organizational_unit_name} development account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${aws_organizations_account.development-account.id}:role/OrganizationAccountAccessRole"
      }
    ]
  })
}

resource "aws_iam_policy" "uat-assume-role-policy" {
  name        = "${var.organizational_unit_name}UATAssumeRolePolicy"
  description = "Assume role for ${var.organizational_unit_name} uat account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${aws_organizations_account.uat-account.id}:role/OrganizationAccountAccessRole"
      }
    ]
  })
}

resource "aws_iam_policy" "production-assume-role-policy" {
  name        = "${var.organizational_unit_name}ProductionAssumeRolePolicy"
  description = "Assume role for ${var.organizational_unit_name} production account"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${aws_organizations_account.production-account.id}:role/OrganizationAccountAccessRole"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "devops-policy-attach" {
  user       = var.master_user_name
  policy_arn = aws_iam_policy.devops-assume-role-policy.arn
}

resource "aws_iam_user_policy_attachment" "development-policy-attach" {
  user       = var.master_user_name
  policy_arn = aws_iam_policy.devops-assume-role-policy.arn
}

resource "aws_iam_user_policy_attachment" "uat-policy-attach" {
  user       = var.master_user_name
  policy_arn = aws_iam_policy.devops-assume-role-policy.arn
}

resource "aws_iam_user_policy_attachment" "production-policy-attach" {
  user       = var.master_user_name
  policy_arn = aws_iam_policy.devops-assume-role-policy.arn
}
