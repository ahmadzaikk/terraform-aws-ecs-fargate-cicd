resource "aws_codedeploy_deployment_group" "this" {
  count = var.enable_blue_green ? 1 : 0  # only create if you actually want Blue/Green

  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${var.name}-service-deploy-group"
  service_role_arn      = aws_iam_role.codedeploy.arn

  ecs_service {
    cluster_name = var.cluster_name
    service_name = var.service_name
  }

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
