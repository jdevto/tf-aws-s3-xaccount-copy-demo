output "account_b_s3_bucket_name" {
  description = "The name of the destination S3 bucket."
  value       = module.s3_bucket.bucket_id
}

output "account_b_s3_bucket_arn" {
  description = "The ARN of the destination S3 bucket."
  value       = module.s3_bucket.bucket_arn
}

output "account_b_sqs_queue_name" {
  description = "The name of the SQS queue receiving SNS messages."
  value       = aws_sqs_queue.research_data.name
}

output "account_b_sqs_queue_arn" {
  description = "The ARN of the SQS queue."
  value       = aws_sqs_queue.research_data.arn
}

output "account_b_sqs_queue_url" {
  description = "The URL of the SQS queue."
  value       = aws_sqs_queue.research_data.id
}

output "account_b_sns_subscription_arn" {
  description = "The ARN of the SNS subscription to the SQS queue."
  value       = aws_sns_topic_subscription.sqs_sub.arn
}
