resource "aws_s3_bucket" "pipeline" {
  bucket = "${var.name}-codepipeline-bucket"
  tags = var.tags
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

 resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = join("", aws_s3_bucket.pipeline.id)

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "${var.name}Codepipeline",
  "Statement": [
        {
            "Sid": "DenyUnEncryptedObjectUploads",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.name}-codepipeline-bucket/*",
            "Condition": {
                "StringNotEquals": {
                    "s3:x-amz-server-side-encryption": "aws:kms"
                }
            }
        },
        {
            "Sid": "DenyInsecureConnections",
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::${var.name}-codepipeline-bucket/*",
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
POLICY
}

data "aws_iam_policy_document" "assume_by_pipeline" {
  statement {
    sid = "AllowAssumeByPipeline"
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline" {
  name = "${var.name}-pipeline-ecs-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_by_pipeline.json
}

data "aws_iam_policy_document" "pipeline" {
  statement {
    sid = "AllowS3"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowECR"
    effect = "Allow"

    actions = ["ecr:DescribeImages"]
    resources = ["*"]
  }

  statement {
    sid = "AllowCodebuild"
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowCodedepoloy"
    effect = "Allow"

    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplication",
      "codedeploy:GetApplicationRevision",
      "codedeploy:GetDeployment",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }
  
  statement {
    sid = "AllowCodecommit"
    effect = "Allow"

    actions = [
      "codecommit:*"
    ]
    resources = ["*"]
  }

  statement {
    sid = "AllowResources"
    effect = "Allow"

    actions = [
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
      "ecs:*",
      "opsworks:*",
      "devicefarm:*",
      "servicecatalog:*",
      "iam:PassRole"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "pipeline" {
  role = aws_iam_role.pipeline.name
  policy = data.aws_iam_policy_document.pipeline.json
}

resource "aws_codepipeline" "this" {
  name = "${var.name}-pipeline"
  role_arn = aws_iam_role.pipeline.arn

  artifact_store {
    location = "${var.name}-codepipeline-bucket"
    type = "S3"
  }

  stage {
    name = "Source"

    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeCommit"
      version = "1"
      output_artifacts = ["SourceArtifact"]

      configuration = {
        RepositoryName = var.repositoryname
        BranchName     = var.branchname
        
      }
    }
  }

  stage {
    name = "Build"

    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = "1"
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]

      configuration = {
        ProjectName = aws_codebuild_project.this.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name = "blue-green"
      category = "Deploy"
      owner = "AWS"
      provider = "CodeDeployToECS"
      input_artifacts = ["BuildArtifact"]
      version = "1"

      configuration = {
        ApplicationName = "${var.name}-service-deploy"
        DeploymentGroupName = "${var.name}-service-deploy-group"
        Image1ArtifactName = "BuildArtifact"
        Image1ContainerName = "IMAGE1_NAME"
        TaskDefinitionTemplateArtifact = "BuildArtifact"
        TaskDefinitionTemplatePath = "taskdef.json"
        AppSpecTemplateArtifact = "BuildArtifact"
        AppSpecTemplatePath = "appspec.yaml"
      }
    }
  }
}
