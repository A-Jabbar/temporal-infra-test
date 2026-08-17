variable "vpc_id" {
  description = "ID of the VPC in which to provision the web tier"
  type        = string
}

variable "private_subnet_ids" {
  description = "Map of availability zone to private subnet ID for the ASG and ALB"
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

variable "instance_type" {
  description = "EC2 instance type for the web tier instances"
  type        = string
  default     = "t3.small"
}

variable "ami_owner" {
  description = "Owner of the base AMI to select"
  type        = string
  default     = "amazon"
}

variable "health_check_path" {
  description = "Path the target group health check uses"
  type        = string
  default     = "/health"
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group"
  type        = number
  default     = 6
}

variable "cpu_target_value" {
  description = "Target average CPU utilization for the target tracking scaling policy"
  type        = number
  default     = 60
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the ALB HTTPS listener (required)"
  type        = string
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the internet-facing ALB on HTTPS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
