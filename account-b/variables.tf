variable "account_a_id" {
  description = "AWS Account A (producer) ID"
  type        = string
}

variable "account_a_bucket_arn" {
  description = "ARN of the source S3 bucket in Account A"
  type        = string
}

variable "account_a_sns_topic_arn" {
  description = "SNS topic ARN in Account A"
  type        = string
}

variable "account_b_suffix" {
  description = "Suffix to append to resource names"
  type        = string
}
