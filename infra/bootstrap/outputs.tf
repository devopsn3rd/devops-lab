output "AWS_ROLE_ARN" {
  description = "Paste into GitHub > Settings > Secrets and variables > Actions > Variables"
  value       = aws_iam_role.github_deploy.arn
}

output "TF_STATE_BUCKET" {
  value = aws_s3_bucket.tfstate.bucket
}

output "AWS_REGION" {
  value = var.aws_region
}
