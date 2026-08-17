output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  description = "ID of the Pulsar VPC"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets by availability zone"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets by availability zone"
  value       = module.network.private_subnet_ids
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway"
  value       = module.network.nat_gateway_id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = module.network.internet_gateway_id
}

output "bastion_sg_id" {
  description = "ID of the bastion security group"
  value       = module.network.bastion_sg_id
}

output "app_sg_id" {
  description = "ID of the application security group"
  value       = module.network.app_sg_id
}

output "db_sg_id" {
  description = "ID of the database security group"
  value       = module.network.db_sg_id
}

output "alb_dns_name" {
  description = "DNS name of the Pulsar web ALB"
  value       = module.web.alb_dns_name
}

output "alb_id" {
  description = "ID of the Pulsar web ALB"
  value       = module.web.alb_id
}

output "target_group_arn" {
  description = "ARN of the Pulsar web target group"
  value       = module.web.target_group_arn
}

output "asg_id" {
  description = "ID of the Pulsar web Auto Scaling Group"
  value       = module.web.asg_id
}

output "web_sg_id" {
  description = "ID of the Pulsar web instance security group"
  value       = module.web.web_sg_id
}

output "alb_sg_id" {
  description = "ID of the Pulsar web ALB security group"
  value       = module.web.alb_sg_id
}
