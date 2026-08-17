output "log_bucket_id" {
  description = "ID (name) of the security log S3 bucket"
  value       = aws_s3_bucket.security_logs.id
}

output "log_bucket_arn" {
  description = "ARN of the security log S3 bucket"
  value       = aws_s3_bucket.security_logs.arn
}

output "cloudtrail_id" {
  description = "Name of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.security[0].id : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = var.enable_cloudtrail ? aws_cloudtrail.security[0].arn : null
}

output "flow_log_ids" {
  description = "Map of VPC ID to VPC Flow Log ID"
  value       = { for vpc_id, flow_log in aws_flow_log.security : vpc_id => flow_log.id }
}
