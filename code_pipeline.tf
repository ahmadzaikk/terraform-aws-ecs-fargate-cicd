locals {
  codepipeline_name = var.codepipeline_name != "" ? var.codepipeline_name : var.name
}

resource "aws_s3_bucket" "pipeline" {
  bucket = lower("${local.codepipeline_name}-codepipeline-bucket")
  tags   = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.pipeline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "pipeline" {
  bucket = aws_s3_bucket.pipeline.id
  policy = data.aws_iam_policy_document.pipeline_bucket_policy.json
}

data "aws_iam_policy_document" "pipeline_bucket_base" {
  policy_id = "SSEAndSSLPolicy"

  statement {
    sid       = "DenyUnEncryptedObjectUploads"
    effect    = "Deny"
    resources = ["${aws_s3_bucket.pipeline.arn}/*"]
    actions   = ["s3:PutObject"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "DenyInsecureConnections"
    effect    = "Deny"
    resources = ["${aws_s3_bucket.pipeline.arn}/*"]
    actions   = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

data "aws_iam_policy_document" "pipeline_bucket_cross_account" {
  statement {
    sid       = "AllowCrossAccountObjectActions"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.pipeline.arn}/*"]
    actions   = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    principals {
      type        = "AWS"
      identifiers = [for account_id in var.codepipeline_cross_account_ids : "arn:aws:iam::${account_id}:root"]
    }
  }

  statement {
    sid       = "AllowCrossAccountBucketActions"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.pipeline.arn}"]
    actions   = ["s3:ListBucket"]

    principals {
      type        = "AWS"
      identifiers = [for account_id in var.codepipeline_cross_account_ids : "arn:aws:iam::${account_id}:root"]
    }
  }
}

data "aws_iam_policy_document" "pipeline_bucket_policy" {
  source_policy_documents = length(var.codepipeline_cross_account_ids) == 0 ? [
    data.aws_iam_policy_document.pipeline_bucket_base.json
  ] : [
    data.aws_iam_policy_document.pipeline_bucket_base.json,
    data.aws_iam_policy_document.pipeline_bucket_cross_account.json
  ]
}

resource "aws_s3_bucket_public_access_block" "this" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.pipeline.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "assume_by_pipeline" {
  statement {
    sid     = "AllowAssumeByPipeline"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name               = "${local.codepipeline_name}-pipeline-ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_pipeline.json
  tags               = var.tags
}

# This policy is based on AWS default, with removal of several actions
# verified as unused via review of CloudTrail.  See also:
# https://docs.aws.amazon.com/codepipeline/latest/userguide/security-iam.html#how-to-custom-role
data "aws_iam_policy_document" "pipeline_base" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions   = ["iam:PassRole"]

    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "codecommit:CancelUploadArchive",
      "codecommit:GetBranch",
      "codecommit:GetCommit",
      "codecommit:GetRepository",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:UploadArchive",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:TagResource",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.pipeline.arn}"]

    actions = [
      "s3:ListBucket",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["${aws_s3_bucket.pipeline.arn}/*"]

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
  }

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch",
    ]
  }
}

data "aws_iam_policy_document" "pipeline_cross_account_role_assume" {
  count       = var.codepipeline_cross_account_role_arn != null ? 1 : 0
  statement {
    sid       = "AllowCrossAccountRoleAssume"
    effect    = "Allow"
    resources = [var.codepipeline_cross_account_role_arn]
    actions   = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "pipeline_kms" {
  count       = var.codepipeline_kms_key_arn != null ? 1 : 0
  statement {
    sid       = "AllowKMSActions"
    effect    = "Allow"
    resources = [var.codepipeline_kms_key_arn]

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey",
      "kms:Encrypt",
      "kms:Decrypt",
    ]
  }
}

data "aws_iam_policy_document" "pipeline" {
  source_policy_documents = (var.codepipeline_cross_account_role_arn == null && var.codepipeline_kms_key_arn == null) ? [
    data.aws_iam_policy_document.pipeline_base.json
  ] : [
    data.aws_iam_policy_document.pipeline_base.json,
    data.aws_iam_policy_document.pipeline_cross_account_role_assume[0].json,
    data.aws_iam_policy_document.pipeline_kms[0].json
  ]
}

resource "aws_iam_role_policy" "pipeline" {
  role   = aws_iam_role.pipeline.name
  policy = data.aws_iam_policy_document.pipeline.json
}

resource "aws_codepipeline" "this" {
  name     = "${local.codepipeline_name}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = aws_s3_bucket.pipeline.id
    type     = "S3"
    dynamic "encryption_key" {
      for_each = var.codepipeline_kms_key_arn[*]
      content {
        id    = var.codepipeline_kms_key_arn
        type  = "KMS"
      }
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      role_arn         = var.codepipeline_cross_account_role_arn
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName       = var.repositoryname
        BranchName           = var.branchname
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
  name = "Deploy"

  action {
    name            = "blue-green"
    category        = "Deploy"
    owner           = "AWS"
    provider        = "CodeDeployToECS"
    input_artifacts = ["BuildArtifact"]
    version         = "1"

    configuration = {
      ApplicationName = var.enable_blue_green ? aws_codedeploy_app.this[0].name : ""
      DeploymentGroupName = var.enable_blue_green ? aws_codedeploy_deployment_group.this[0].deployment_group_name : ""
      Image1ArtifactName             = "BuildArtifact"
      Image1ContainerName            = "IMAGE1_NAME"
      TaskDefinitionTemplateArtifact = "BuildArtifact"
      TaskDefinitionTemplatePath     = "taskdef.json"
      AppSpecTemplateArtifact        = "BuildArtifact"
      AppSpecTemplatePath            = "appspec.yaml"
    }
  }
}

  tags = var.tags
}
