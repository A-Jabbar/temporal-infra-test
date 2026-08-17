data "aws_caller_identity" "current" {}

locals {
  log_bucket = "pulsar-security-logs-${data.aws_caller_identity.current.account_id}"

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
  })
}

# -----------------------------------------------------------------------------
# Security log S3 bucket (private, encrypted, lifecycle-managed)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "security_logs" {
  bucket        = local.log_bucket
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = local.log_bucket
  })
}

resource "aws_s3_bucket_acl" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id

  rule {
    id     = "expire-security-logs"
    status = "Enabled"

    filter {}

    expiration {
      days = var.log_retention_days
    }
  }
}

data "aws_iam_policy_document" "security_logs" {
  statement {
    sid    = "AllowCloudTrailToWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.security_logs.arn,
      "${aws_s3_bucket.security_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]
  }

  statement {
    sid    = "AllowVpcFlowLogsToWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:PutObject",
    ]
    resources = [
      aws_s3_bucket.security_logs.arn,
      "${aws_s3_bucket.security_logs.arn}/vpc-flow-logs/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "security_logs" {
  bucket = aws_s3_bucket.security_logs.id
  policy = data.aws_iam_policy_document.security_logs.json
}

# -----------------------------------------------------------------------------
# CloudTrail trail (multi-region, log file validation)
# -----------------------------------------------------------------------------
resource "aws_cloudtrail" "security" {
  count = var.enable_cloudtrail ? 1 : 0

  name                          = "pulsar-security-trail"
  s3_bucket_name                = aws_s3_bucket.security_logs.id
  is_multi_region_trail         = var.cloudtrail_multi_region
  enable_log_file_validation    = var.enable_cloudtrail_log_file_validation
  include_global_service_events = true
  is_organization_trail         = false

  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# VPC Flow Logs to the security log bucket
# -----------------------------------------------------------------------------
resource "aws_flow_log" "security" {
  for_each = var.enable_vpc_flow_logs ? toset(var.vpc_ids) : toset([])

  vpc_id                   = each.value
  log_destination_type     = "s3"
  log_destination          = aws_s3_bucket.security_logs.arn
  traffic_type             = "ALL"
  max_aggregation_interval = 600

  destination_options {
    file_format        = "plain-text"
    per_hour_partition = true
  }

  tags = merge(local.common_tags, {
    Name = "pulsar-flow-log-${each.value}"
  })
}
