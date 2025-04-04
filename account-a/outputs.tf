output "account_a_bucket_name" {
  description = "The name of the S3 bucket created in Account A (source bucket for cross-account operations)."
  value       = module.s3_bucket.bucket_id
}

output "account_a_bucket_arn" {
  description = "The ARN of the S3 bucket in Account A (used for permissions and event sources)."
  value       = module.s3_bucket.bucket_arn
}

output "account_a_sns_topic_name" {
  description = "Name of the SNS topic for S3 events"
  value       = aws_sns_topic.s3_events.name
}

output "account_a_sns_topic_arn" {
  description = "ARN of the SNS topic for S3 events"
  value       = aws_sns_topic.s3_events.arn
}

output "account_b_suffix" {
  description = "The suffix applied to resource names in Account B"
  value       = random_string.account_b_suffix.result
}
