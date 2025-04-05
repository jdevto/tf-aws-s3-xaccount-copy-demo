############################################
# Random Suffix and Local Variables
############################################

locals {
  name   = "xaccount-copy"
  suffix = var.account_b_suffix
  tags = {
    Environment = "dev"
    Project     = "example-project"
  }
  files_queue = fileset("${path.module}/external/queue", "**")
  hash_queue = md5(
    join(
      "",
      [for f in local.files_queue : "${f}:${filemd5("${path.module}/external/queue/${f}")}"]
    )
  )
}

############################################
# Destination S3 Bucket
############################################

module "s3_bucket" {
  source = "tfstack/s3/aws"

  bucket_name       = local.name
  bucket_suffix     = local.suffix
  force_destroy     = true
  enable_versioning = false
  logging_enabled   = false

  tags = merge(local.tags, {
    Name = "${local.name}-${local.suffix}"
  })
}

############################################
# SQS Configuration
############################################

resource "aws_sqs_queue" "research_data" {
  name = "${local.name}-research-data"

  tags = merge(local.tags, {
    Name = "${local.name}-research-data"
  })
}

resource "aws_sqs_queue_policy" "allow_sns_from_account_a" {
  queue_url = aws_sqs_queue.research_data.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "SQS:SendMessage",
        Resource  = aws_sqs_queue.research_data.arn,
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.account_a_sns_topic_arn
          }
        }
      }
    ]
  })
}

############################################
# SNS Subscription (Account A)
############################################

resource "aws_sns_topic_subscription" "sqs_sub" {
  topic_arn = var.account_a_sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.research_data.arn

  raw_message_delivery = true

  depends_on = [
    aws_sqs_queue_policy.allow_sns_from_account_a
  ]
}

############################################
# Lambda Consumer to process SQS messages and upload to S3
############################################

resource "aws_cloudwatch_log_group" "queue" {
  name              = "/aws/lambda/${local.name}-research-data"
  retention_in_days = 1

  tags = merge(local.tags, {
    Name = "${local.name}-research-data"
  })
}

resource "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/external/queue"
  output_path = "${path.module}/external/queue.zip"
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.name}-lambda-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_exec" {
  name = "${local.name}-lambda-exec"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowSQSAccess",
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.research_data.arn
      },
      {
        Sid    = "AllowS3PutToDestination",
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${module.s3_bucket.bucket_arn}/*"
      },
      {
        Sid    = "AllowS3GetFromSource",
        Effect = "Allow",
        Action = [
          "s3:GetObject"
        ],
        Resource = "${var.account_a_bucket_arn}/*"
      },
      {
        Sid    = "AllowCloudWatchLogging",
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "research_data" {
  function_name = "${local.name}-research-data"
  runtime       = "nodejs22.x"
  handler       = "index.handler"
  timeout       = 30
  role          = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      BUCKET_NAME = module.s3_bucket.bucket_id
      DEBUG       = "true"
    }
  }

  filename         = archive_file.lambda.output_path
  source_code_hash = local.hash_queue

  depends_on = [
    archive_file.lambda,
    aws_cloudwatch_log_group.queue
  ]

  tags = merge(local.tags, {
    Name = "${local.name}-research-data"
  })
}

resource "aws_lambda_event_source_mapping" "research_data" {
  event_source_arn = aws_sqs_queue.research_data.arn
  function_name    = aws_lambda_function.research_data.arn
  batch_size       = 1
}
