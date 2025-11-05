variable "name" {
  type       = string
  default     = "cluster"
}
variable "privileged_mode" {
  default     = true
  description = "Set to `false` to prevent Database accessibility"
  type        = bool
}
variable "enable_blue_green" {
  description = "If true, use Blue/Green ECS deployment; if false, use in-place deployment"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "repositoryname" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "repository_arn" {
  description = "The repo arn."
  type        = string
  default     = null
}
variable "branchname" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "cross_account_branchname" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "execution_role" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "task_role" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "ecr_repository_arns" {
  description = "ECR repository ARNs"
  type        = list(string)
  default     = ["*"]
}
variable "allowed_s3_bucket_names" {
  description = "S3 buckets for which access will be granted in IAM policies"
  type        = list(string)
  default     = ["*"]
}
variable "codepipeline_cross_account_ids" {
  description = "(Optional) account IDs that will be granted access to codepipeline bucket"
  type        = list(string)
  default     = []
}
variable "codepipeline_cross_account_role_arn" {
  description = "(Optional) role ARN that CodePipeline service role will be granted access to assume"
  type        = string
  default     = null
}
variable "codepipeline_kms_key_arn" {
  description = "(Optional) ARN of KMS key used to encrypt CodePipeline artifacts uploaded to S3"
  type        = string
  default     = null
}
variable "codepipeline_name" {
  description = "(Optional) custom name for pipeline"
  type        = string
  default     = ""
}
variable "eventbridge_cross_account_ids" {
  description = "(Optional) account IDs we allow our eventbridge role to PutEvents to (for triggering cross account pipeline execution)"
  type        = list(string)
  default     = []
}

variable "listener_arns" {
  description = "The resource name."
  type        = list(string)
  default     = null
}
variable "target_group_0" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "target_group_1" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "IMAGE_REPO_NAME" {
  description = "The resource name."
  type        = string
  default     = null
}
variable "SERVICE_PORT" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "compute_type" {
  description = "The resource name."
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "codebuild_name" {
  description = "(Optional) custom name for CodeBuild project"
  type        = string
  default     = ""
}

variable "codebuild_description" {
  description = "(Optional) description for CodeBuild project"
  type        = string
  default     = ""
}

variable "codebuild_image" {
  description = "The resource name."
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:4.0"
}

variable "codebuild_type" {
  description = "The resource name."
  type        = string
  default     = "LINUX_CONTAINER"
}

variable "MEMORY_RESV" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "service_name" {
  description = "The resource name."
  type        = string
  default     = null
}

variable "aws_account_id" {
  default = ""
}

variable "DEPLOY" {
  description = "The resource name."
  type        = string
  default     = ""
}

variable "APP_NAME" {
  description = "Environment variable for consumption in CodeBuild (usually set to ucop:application tag)"
  type        = string
  default     = ""
}

variable "APP_ENVIRONMENT" {
  description = "Environment variable for consumption in CodeBuild (usually set to ucop:environment tag)"
  type        = string
  default     = ""
}

variable "TASK_CPU" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "TASK_MEMORY" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "APACHESHIB_HOST" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "SHIBBOLETH_SP_BACKEND_AJP_SECRET_ARN" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "SHIBBOLETH_SP_JSON_CERTS_SECRET_ARN" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "SHIBBOLETH_SP_SPOOFKEY_SECRET_ARN" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "SHIBBOLETH_SP_JSON_CONF_SECRET_ARN" {
  description = "Environment variable for consumption in CodeBuild"
  type        = string
  default     = ""
}

variable "cloudwatch_event_rule_state" {
  description = "State of event rules that trigger CodePipline. Set to DISABLED if commits should not trigger the pipeline."
  type        = string
  default     = "ENABLED"
}

variable "pipeline_schedule_expression" {
  description = "(Optional) schedule expression for automatically triggering pipeline"
  type        = string
  default     = null
}

variable "pipeline_schedule_expression_timezone" {
  description = "(Optional) timezone associated with pipeline_schedule_expression"
  type        = string
  default     = "US/Pacific"
}

variable "pipeline_schedule_maximum_window_in_minutes" {
  description = "(Optional) maximum time window during which a schedule can be invoked"
  type        = string
  default     = null
}

variable "region" {
  default = "us-west-2"
}

variable "tags" {
  default     = {}
  description = "A map of tags to add to all resources"
  type        = map(string)
}
