output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.this.id
}

output "db_endpoint" {
  description = "Address/hostname of the RDS instance (endpoint)"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port on which the database listens"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}

output "db_subnet_group_id" {
  description = "ID of the DB subnet group"
  value       = aws_db_subnet_group.this.id
}
