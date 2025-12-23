# CloudTrail configuration for API activity monitoring

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# S3 Bucket for CloudTrail logs with proper security settings
resource "aws_s3_bucket" "clixx_cloudtrail_logs" {
  bucket        = "clixx-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Set to false in production

  tags = merge(
    var.common_tags,
    {
      Name = "clixx-cloudtrail-logs"
    },
    local.custom_tags
  )

  depends_on = [aws_vpc.main]
}

# Block public access for the CloudTrail logs bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_block_public_access" {
  bucket = aws_s3_bucket.clixx_cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy to allow CloudTrail to write logs
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.clixx_cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.clixx_cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.clixx_cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail_block_public_access]
}

# Enable S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_encryption" {
  bucket = aws_s3_bucket.clixx_cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Create CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_log_group" {
  name              = "/aws/cloudtrail/clixx-trail"
  retention_in_days = 90

  tags = merge(
    var.common_tags,
    {
      Name = "clixx-cloudtrail-log-group"
    },
    local.custom_tags
  )
}

# IAM role for CloudTrail to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "cloudtrail-to-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "clixx-cloudtrail-to-cloudwatch-role"
    },
    local.custom_tags
  )
}

# IAM policy for CloudTrail to CloudWatch Logs
resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch_policy" {
  name = "cloudtrail-to-cloudwatch-policy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
      }
    ]
  })
}

# CloudTrail configuration
resource "aws_cloudtrail" "clixx_trail" {
  name                          = "clixx-trail"
  s3_bucket_name                = aws_s3_bucket.clixx_cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "clixx-cloudtrail"
    },
    local.custom_tags
  )

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_bucket_policy,
    aws_cloudwatch_log_group.cloudtrail_log_group,
    aws_iam_role_policy.cloudtrail_to_cloudwatch_policy
  ]
}