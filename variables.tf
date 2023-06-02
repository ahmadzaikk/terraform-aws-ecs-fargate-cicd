variable "name" {
  type       = string
  default     = "cluster"
}
variable "privileged_mode" {
  default     = true
  description = "Set to `false` to prevent Database accessibility"
  type        = bool
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

variable "region" {
  default = "us-west-2"
}
variable "tags" {
  default     = {}
  description = "A map of tags to add to all resources"
  type        = map(string)
}
