resource "aws_security_group" "bastion" {
  name        = "Pulsar-bastion-sg"
  description = "Security group for bastion hosts allowing SSH from approved CIDR"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from approved CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.bastion_allowed_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "Pulsar-bastion-sg"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_security_group" "app" {
  name        = "Pulsar-app-sg"
  description = "Security group for application tier"
  vpc_id      = aws_vpc.this.id

  dynamic "ingress" {
    for_each = var.app_ports
    content {
      description = "Application port ${ingress.value} from VPC CIDR"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "Pulsar-app-sg"
    Environment = var.environment
    Project     = var.project_name
  })
}

resource "aws_security_group" "db" {
  name        = "Pulsar-db-sg"
  description = "Security group for database tier (no internet access)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "Database port from app security group"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = merge(var.tags, {
    Name        = "Pulsar-db-sg"
    Environment = var.environment
    Project     = var.project_name
  })
}
