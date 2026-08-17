variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "pulsar"
}

variable "tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_ids" {
  description = "List of VPC IDs to enable VPC Flow Logs for"
  type        = list(string)
}

variable "log_retention_days" {
  description = "Number of days to retain security logs in the S3 bucket before expiration"
  type        = number
  default     = 2557
}

variable "enable_cloudtrail" {
  description = "Whether to enable the CloudTrail trail"
  type        = bool
  default     = true
}

variable "cloudtrail_multi_region" {
  description = "Whether the CloudTrail trail is a multi-region trail"
  type        = bool
  default     = true
}

variable "enable_cloudtrail_log_file_validation" {
  description = "Whether to enable CloudTrail log file validation"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "Whether to enable VPC Flow Logs for the provided VPCs"
  type        = bool
  default     = true
}
