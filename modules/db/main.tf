# KMS key for encryption at rest
resource "aws_kms_key" "rds" {
  description             = "KMS key for encrypting the Pulsar RDS PostgreSQL database"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name        = "pulsar-rds-kms"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/pulsar-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# DB subnet group on the private subnets
resource "aws_db_subnet_group" "this" {
  name        = "pulsar-db-subnet-group"
  description = "Private subnets for Pulsar PostgreSQL"
  subnet_ids  = var.private_subnet_ids

  tags = merge(var.tags, {
    Name        = "pulsar-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  })
}

# Allow the web tier security group to reach the database on the DB port
resource "aws_security_group_rule" "db_from_web" {
  type                     = "ingress"
  security_group_id        = var.db_sg_id
  description              = "Database port from web tier security group"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.web_sg_id
}

# Encrypted, Multi-AZ RDS PostgreSQL instance
resource "aws_db_instance" "this" {
  identifier = "pulsar-postgres"

  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  storage_type            = "gp3"
  allocated_storage       = var.allocated_storage
  max_allocated_storage   = var.max_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  port                    = var.db_port
  multi_az                = var.multi_az
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [var.db_sg_id]
  publicly_accessible     = false
  backup_retention_period = var.backup_retention_days
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.rds.arn
  deletion_protection     = true
  skip_final_snapshot     = false

  tags = merge(var.tags, {
    Name        = "pulsar-postgres"
    Environment = var.environment
    Project     = var.project_name
  })
}
