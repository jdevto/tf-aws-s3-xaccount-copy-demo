############################################
# Identity and Random Suffix
############################################

data "aws_caller_identity" "current" {}

resource "random_string" "account_a_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_string" "account_b_suffix" {
  length  = 6
  special = false
  upper   = false
}

############################################
# Locals
############################################

locals {
  name   = "xaccount-copy"
  suffix = random_string.account_a_suffix.result
  tags = {
    Environment = "dev"
    Project     = "example-project"
  }
}

############################################
# S3 Bucket
############################################

module "s3_bucket" {
  source = "tfstack/s3/aws"

  bucket_name       = local.name
  bucket_suffix     = local.suffix
  force_destroy     = true
  enable_versioning = false
  logging_enabled   = false

  tags = merge(local.tags, { Name = "${local.name}-${local.suffix}" })
}

resource "aws_s3_bucket_policy" "allow_account_b" {
  bucket = module.s3_bucket.bucket_id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowAccountBReadAccess",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.account_b_id}:role/xaccount-copy-lambda-exec"
        },
        Action   = ["s3:GetObject"],
        Resource = "${module.s3_bucket.bucket_arn}/*"
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "bucket_events" {
  bucket = module.s3_bucket.bucket_id

  topic {
    topic_arn = aws_sns_topic.s3_events.arn
    events    = ["s3:ObjectCreated:*"]
  }

  depends_on = [
    aws_sns_topic_policy.allow_account_b
  ]
}

############################################
# SNS for S3 Events
############################################

resource "aws_sns_topic" "s3_events" {
  name = "${local.name}-s3-events"

  tags = merge(local.tags, { Name = "${local.name}-s3-events" })
}

resource "aws_sns_topic_policy" "allow_account_b" {
  arn = aws_sns_topic.s3_events.arn

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowS3ToPublish",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action   = "SNS:Publish",
        Resource = aws_sns_topic.s3_events.arn,
        Condition = {
          ArnLike = {
            "aws:SourceArn" = module.s3_bucket.bucket_arn
          }
        }
      },
      {
        Sid    = "AllowAccountBToSubscribe",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${var.account_b_id}:root"
        },
        Action = [
          "SNS:Subscribe",
          "SNS:Receive",
          "SNS:ListSubscriptionsByTopic",
          "SNS:GetTopicAttributes"
        ],
        Resource = aws_sns_topic.s3_events.arn
      }
    ]
  })
}
