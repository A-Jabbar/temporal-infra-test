variable "private_subnet_ids" {
  description = "IDs of the private subnets in which the RDS instance will be deployed"
  type        = list(string)
}

variable "db_sg_id" {
  description = "ID of the database security group to attach to the RDS instance"
  type        = string
}

variable "web_sg_id" {
  description = "ID of the web tier security group allowed to reach the database on the DB port"
  type        = string
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
  description = "Default tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "db_name" {
  description = "Name of the initial database to create"
  type        = string
  default     = "pulsar"
}

variable "db_username" {
  description = "Master username for the RDS instance"
  type        = string
  default     = "pulsar_admin"
}

variable "db_password" {
  description = "Master password for the RDS instance (required, no default)"
  type        = string
  sensitive   = true
}

variable "db_port" {
  description = "Port on which the database listens"
  type        = number
  default     = 5432
}

variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15"
}

variable "instance_class" {
  description = "DB instance class"
  type        = string
  default     = "db.t4g.small"
}

variable "allocated_storage" {
  description = "Allocated storage size in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage size in GB when storage autoscaling is enabled"
  type        = number
  default     = 100
}

variable "multi_az" {
  description = "Whether to create a standby replica in a different AZ for high availability"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7
}
