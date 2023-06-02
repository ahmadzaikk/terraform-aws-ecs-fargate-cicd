resource "aws_s3_bucket" "pipeline" {
  bucket = "${var.name}-codepipeline-bucket"
  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.pipeline.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
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
        PollForSourceChanges = "false"
        
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


## EventBridge rule to trigger the pipeline 
module "eventbridge" {
  source                 = "git::https://git@github.com/ucopacme/terraform-aws-eventbridge//?ref=v0.0.1"
  pipeline_arn           = aws_codepipeline.this.arn
  create_bus             = false
  create_role            = true
  attach_pipeline_policy = true
  role_name              = join("-", [local.application, local.environment, "eventbridge"])
  rules = {
    Eventbridge = {
      description = "Trigger for a codepipeline"
      event_pattern = jsonencode({ "source" : ["aws.codecommit"], "detail-type" : ["CodeCommit Repository State Change"], "resources" : [module.codecommit.arn], "detail" : {
      "event" : ["referenceCreated", "referenceUpdated"], "referenceType" : ["branch"], "referenceName" : ["master"] } })
    }
  }

  targets = {
    Eventbridge = [
      {
        name                   = join("-", [local.application, local.environment, "eventbridge"])
        arn                    = aws_codepipeline.this.arn
        role_arn               = module.eventbridge.eventbridge_role_arn
        attach_pipeline_policy = true
        attach_role_arn        = true
      }

    ]
  }
  tags = {
    "ucop:application" = local.application
    "ucop:createdBy"   = local.createdBy
    "ucop:environment" = local.environment
    "ucop:group"       = local.group
    "ucop:source"      = local.source
  }
}
