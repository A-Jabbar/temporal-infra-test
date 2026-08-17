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
