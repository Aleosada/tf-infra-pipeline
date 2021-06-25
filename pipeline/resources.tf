#############################################################################
# RESOURCES
#############################################################################

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

###################################################
# CODE BUILD
###################################################

locals {
  build_logs_bucket_name         = "${var.aws_build_logs_bucket_prefix}-${random_integer.rand.result}"
}

resource "aws_s3_bucket" "build_logs" {
  bucket        = local.build_logs_bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_iam_role" "code_build_assume_role" {
  name = "code-build-assume-role-${random_integer.rand.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloud_build_policy" {
  role = aws_iam_role.code_build_assume_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
            "Effect": "Allow",
            "Action": ["dynamodb:*"],
            "Resource": [
                "${data.aws_dynamodb_table.state_table.arn}"
            ]
        },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${data.aws_s3_bucket.state_bucket.arn}",
        "${data.aws_s3_bucket.state_bucket.arn}/*",
        "${aws_s3_bucket.build_logs.arn}",
        "${aws_s3_bucket.build_logs.arn}/*"
      ]
    }
  ]
}
POLICY
}

resource "aws_codebuild_project" "build_project" {
  name          = "deploy-${var.project_name}"
  description   = var.project_description
  build_timeout = "5"
  service_role  = aws_iam_role.code_build_assume_role.arn

  artifacts {
    type     = "S3"
    location = aws_s3_bucket.build_logs.bucket
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "TF_ACTION"
      value = "PLAN"
    }

    environment_variable {
      name  = "TF_VERSION_INSTALL"
      value = "1.0.1"
    }

    environment_variable {
      name  = "TF_BUCKET"
      value = var.state_bucket
    }

    environment_variable {
      name = "TF_TABLE"
      value = var.dynamodb_state_table_name
    }

    environment_variable {
      name  = "TF_REGION"
      value = var.region
    }

    environment_variable {
      name  = "WORKSPACE_NAME"
      value = "Default"
    }

  }

  logs_config {

    s3_logs {
      status   = "ENABLED"
      location = "${aws_s3_bucket.build_logs.id}/build-log"
    }
  }

  source {
    type            = "GITHUB"
    location        = "https://github.com/${var.repository_id}"
    git_clone_depth = 1

    git_submodules_config {
      fetch_submodules = true
    }
  }
  source_version = "main"
}

###################################################
# CODE PIPELINE
###################################################

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.project_name}-codepipeline-role-${random_integer.rand.result}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.project_name}-codepipeline_policy-${random_integer.rand.result}"
  role = aws_iam_role.codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "*",
            "Effect": "Allow",
            "Condition": {
                "StringEqualsIfExists": {
                    "iam:PassdToService": [
                        "cloudformation.amazonaws.com",
                        "elasticbeanstalk.amazonaws.com",
                        "ec2.amazonaws.com",
                        "ecs-tasks.amazonaws.com"
                    ]
                }
            }
        },
                {
            "Action": [
                "codecommit:CancelUploadArchive",
                "codecommit:GetBranch",
                "codecommit:GetCommit",
                "codecommit:GetUploadArchiveStatus",
                "codecommit:UploadArchive"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "elasticbeanstalk:*",
                "ec2:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "s3:*",
                "sns:*",
                "cloudformation:*",
                "rds:*",
                "sqs:*",
                "ecs:*"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "*"
    }

  ]
}
EOF
}

resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
}

resource "aws_codepipeline" "codepipeline" {
  name     = "${var.project_name}-deploy-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.build_logs.bucket
    type     = "S3"

  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = aws_codestarconnections_connection.github.arn
        FullRepositoryId = var.repository_id
        BranchName       = var.main_branch_name
      }

    }
  }

  stage {
    name = "Development"

    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["Development_plan_output"]
      version          = "1"
      run_order        = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "TF_ACTION"
              value = "PLAN"
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_NAME"
              value = "development"
              type  = "PLAINTEXT"
            }
          ]
        )
      }
    }

    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["Development_apply_output"]
      version          = "1"
      run_order        = "2"

      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "TF_ACTION"
              value = "APPLY"
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_NAME"
              value = "Development"
              type  = "PLAINTEXT"
            }
          ]
        )
      }
    }
  }
/*
  stage {
    name = "UAT"
    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["UAT_plan_output"]
      run_order        = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "TF_ACTION"
              value = "PLAN"
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_NAME"
              value = "UAT"
              type  = "PLAINTEXT"
            }
          ]
        )
      }
    }
    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["UAT_apply_output"]
      run_order        = "2"
      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "TF_ACTION"
              value = "APPLY"
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_NAME"
              value = "UAT"
              type  = "PLAINTEXT"
            }
          ]
        )
      }
    }
  }
  stage {
    name = "Production"
    action {
      name             = "Plan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["Production_plan_output"]
      run_order        = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "TF_ACTION"
              value = "PLAN"
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_NAME"
              value = "Production"
              type  = "PLAINTEXT"
            }
          ]
        )
      }
    }
    action {
      name             = "Approve"
      category         = "Approval"
      owner            = "AWS"
      provider         = "Manual"
      input_artifacts  = []
      output_artifacts = []
      run_order        = "2"
    }
    action {
      name             = "Apply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["Production_apply_output"]
      run_order        = "3"
      configuration = {
        ProjectName = aws_codebuild_project.build_project.name
        EnvironmentVariables = jsonencode(
          [
            {
              name  = "TF_ACTION"
              value = "APPLY"
              type  = "PLAINTEXT"
            },
            {
              name  = "WORKSPACE_NAME"
              value = "Production"
              type  = "PLAINTEXT"
            }
          ]
        )
      }
  }
  */
}
