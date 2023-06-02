output "codepipeline_arn" {
  description = "CodePipeline ARN"
  value       = join("", aws_codepipeline.this.codepipeline_arn)
}

