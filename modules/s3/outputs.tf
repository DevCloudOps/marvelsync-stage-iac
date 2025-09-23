output "app_data_bucket_name" {
  description = "The name of the application data bucket"
  value       = aws_s3_bucket.app_data.bucket
}

output "app_data_bucket_arn" {
  description = "The ARN of the application data bucket"
  value       = aws_s3_bucket.app_data.arn
}

output "s3_access_policy_arn" {
  description = "The ARN of the S3 access policy"
  value       = aws_iam_policy.s3_access.arn
} 