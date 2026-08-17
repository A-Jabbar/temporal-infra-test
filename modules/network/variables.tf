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
}

variable "private_subnet_cidrs" {
  description = "Map of availability zone to private subnet CIDR"
  type        = map(string)
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

variable "tags" {
  description = "Additional tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "bastion_allowed_cidr" {
  description = "CIDR block allowed to SSH into the bastion security group"
  type        = string
  default     = "0.0.0.0/0"
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
