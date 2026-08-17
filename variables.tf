variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "pulsar"
}

variable "default_tags" {
  description = "Default tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "pulsar"
    ManagedBy   = "terraform"
    Environment = "pulsar"
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "Map of availability zone to public subnet CIDR"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.1.0/24"
    "us-east-1b" = "10.0.2.0/24"
    "us-east-1c" = "10.0.3.0/24"
  }
}

variable "private_subnet_cidrs" {
  description = "Map of availability zone to private subnet CIDR"
  type        = map(string)
  default = {
    "us-east-1a" = "10.0.101.0/24"
    "us-east-1b" = "10.0.102.0/24"
    "us-east-1c" = "10.0.103.0/24"
  }
}

# This variable has NO default and MUST be set explicitly. Replace it with your
# office IP range (e.g., "203.0.113.0/24") or a bastion host CIDR before
# applying. Leaving it unset (or wide open) would allow SSH from anywhere,
# which is a security risk.
variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion security group"
  type        = string
}

variable "app_ports" {
  description = "Application ports allowed inbound from the VPC CIDR"
  type        = list(number)
  default     = [8080, 443]
}

variable "db_port" {
  description = "Database port allowed inbound from the app security group"
  type        = number
  default     = 5432
}

# ACM certificate ARN for the web ALB HTTPS listener. This has NO default and
# MUST be set (e.g., request a certificate via AWS Certificate Manager and pass
# its ARN) before applying, otherwise the HTTPS listener cannot be created.
variable "certificate_arn" {
  description = "ARN of the ACM certificate for the web ALB HTTPS listener"
  type        = string
}

variable "web_instance_type" {
  description = "EC2 instance type for the web tier instances"
  type        = string
  default     = "t3.small"
}

variable "web_desired_capacity" {
  description = "Desired number of web instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "web_min_size" {
  description = "Minimum number of web instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "web_max_size" {
  description = "Maximum number of web instances in the Auto Scaling Group"
  type        = number
  default     = 6
}

variable "web_cpu_target_value" {
  description = "Target average CPU utilization for the web target tracking scaling policy"
  type        = number
  default     = 60
}

variable "web_alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the internet-facing web ALB on HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
