output "app_data_bucket_name" {
  description = "The name of the application data bucket"
  value       = aws_s3_bucket.app_data.bucket
}

output "app_data_bucket_arn" {
  description = "The ARN of the application data bucket"
  value       = aws_s3_bucket.app_data.arn
}

# output "static_website_bucket_name" {
#   description = "The name of the static website bucket"
#   value       = aws_s3_bucket.static_website.bucket
# }

# output "static_website_bucket_arn" {
#   description = "The ARN of the static website bucket"
#   value       = aws_s3_bucket.static_website.arn
# }

# output "static_website_endpoint" {
#   description = "The website endpoint of the static website bucket"
#   value       = aws_s3_bucket_website_configuration.static_website.website_endpoint
# }

# output "static_website_domain" {
#   description = "The domain of the static website bucket"
#   value       = aws_s3_bucket_website_configuration.static_website.website_domain
# }

output "s3_access_policy_arn" {
  description = "The ARN of the S3 access policy"
  value       = aws_iam_policy.s3_access.arn
} 