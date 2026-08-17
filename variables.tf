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
