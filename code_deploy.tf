###############################
# IAM Role for CodeDeploy
###############################
resource "aws_iam_role" "codedeploy" {
  count = var.enable_blue_green ? 1 : 0

  name               = "${var.name}-codedeploy"
  assume_role_policy = data.aws_iam_policy_document.assume_by_codedeploy.json
  tags               = var.tags
}

###############################
# CodeDeploy App
###############################
resource "aws_codedeploy_app" "this" {
  count            = var.enable_blue_green ? 1 : 0
  compute_platform = "ECS"
  name             = "${var.name}-service-deploy"
  tags             = var.tags
}

###############################
# IAM Policy for CodeDeploy
###############################
data "aws_iam_policy_document" "codedeploy_base" {
  statement {
    sid    = "AllowAWSCodeDeployForECS"
    effect = "Allow"
    actions = [
      "cloudwatch:DescribeAlarms",
      "ecs:CreateTaskSet",
      "ecs:DeleteTaskSet",
      "ecs:DescribeServices",
      "ecs:TagResource",
      "ecs:UpdateServicePrimaryTaskSet",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyRule",
      "lambda:InvokeFunction",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "sns:Publish",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      var.task_role == null ? var.execution_role : var.execution_role,
      var.task_role
    ]
  }
}

data "aws_iam_policy_document" "codedeploy_kms" {
  count = var.codepipeline_kms_key_arn != null ? 1 : 0
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

data "aws_iam_policy_document" "codedeploy" {
  source_policy_documents = var.codepipeline_kms_key_arn == null ? [
    data.aws_iam_policy_document.codedeploy_base.json
  ] : [
    data.aws_iam_policy_document.codedeploy_base.json,
    data.aws_iam_policy_document.codedeploy_kms[0].json
  ]
}

resource "aws_iam_role_policy" "codedeploy" {
  count  = var.enable_blue_green ? 1 : 0
  role   = aws_iam_role.codedeploy[0].name
  policy = data.aws_iam_policy_document.codedeploy.json
}

###############################
# CodeDeploy Deployment Group
###############################
resource "aws_codedeploy_deployment_group" "this" {
  count = var.enable_blue_green ? 1 : 0

  app_name              = aws_codedeploy_app.this[0].name
  deployment_group_name = "${var.name}-service-deploy-group"
  service_role_arn      = aws_iam_role.codedeploy[0].arn

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

  # Blue/Green deployment style
  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  dynamic "load_balancer_info" {
    for_each = [1]
    content {
      target_group_pair_info {
        prod_traffic_route {
          listener_arns = var.listener_arns
        }

        target_group {
          name = var.target_group_0
        }

        target_group {
          name = var.target_group_1
        }
      }
    }
  }

  dynamic "blue_green_deployment_config" {
    for_each = [1]
    content {
      deployment_ready_option {
        action_on_timeout = "CONTINUE_DEPLOYMENT"
      }

      terminate_blue_instances_on_deployment_success {
        action                           = "TERMINATE"
        termination_wait_time_in_minutes = 1
      }
    }
  }

  tags = var.tags
}
