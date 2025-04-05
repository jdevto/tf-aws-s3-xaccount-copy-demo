# tf-aws-s3-xaccount-copy-demo

Terraform demo showcasing cross-account S3 file copying using an event-driven architecture with S3 → SNS → SQS → Lambda across AWS accounts.

---

## 🔧 Overview

- **Account A** hosts the source S3 bucket and publishes events to SNS.
- **Account B** has an SQS queue subscribed to Account A’s SNS topic.
- A Lambda in Account B processes the SQS messages and copies the uploaded file into its own S3 bucket.

```
   ┌────────────────────────────┐
   │        Account A           │
   │                            │
   │  ┌───────────────┐         │
   │  │  S3 Bucket    │         │
   │  │ (Source)      │         │
   │  └──────┬────────┘         │
   │         │ S3 Event         │
   │         ▼                  │
   │  ┌───────────────┐         │
   │  │    SNS Topic  │◄────────┐
   │  └──────┬────────┘         │
   └─────────┼──────────────────┘
             │ Cross-account Subscription
             ▼
   ┌─────────┼──────────────────┐
   │        Account B           │
   │                            │
   │  ┌───────────────┐         │
   │  │    SQS Queue  │         │
   │  └──────┬────────┘         │
   │         │ Trigger          │
   │         ▼                  │
   │  ┌───────────────┐         │
   │  │    Lambda     │         │
   │  └──────┬────────┘         │
   │         │ CopyObject       │
   │         ▼                  │
   │  ┌───────────────┐         │
   │  │  S3 Bucket    │         │
   │  │ (Destination) │         │
   │  └───────────────┘         │
   └────────────────────────────┘
```

---

## 🚀 Deployment Steps

### ✅ 1. Deploy Base Resources in Account A

```bash
cd ./account-a
```

Apply the minimal initial setup (shared variables + core infra):

```bash
terraform apply \
  -target=random_string.suffix \
  -target=module.s3_bucket \
  -target=aws_sns_topic.s3_events \
  -target=aws_sns_topic_policy.allow_account_b \
  -target=random_string.account_b_suffix
```

---

### ✅ 2. Deploy Base Resources in Account B

```bash
cd ../account-b
```

Set any required variables (e.g., `account_a_sns_topic_arn`, `account_a_bucket_arn`), then:

```bash
terraform apply \
  -target=module.s3_bucket \
  -target=aws_sqs_queue.research_data
```

---

### ✅ 3. Finalize Setup in Account A

```bash
cd ../account-a
terraform apply
```

---

### ✅ 4. Finalize Setup in Account B

```bash
cd ../account-b
terraform apply
```

---

## 🧪 Test It

Upload a file to Account A’s S3 bucket and verify it appears in Account B’s bucket via the Lambda processor.

Check logs in CloudWatch in Account B for Lambda execution results.
