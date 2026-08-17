data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Current AWS account ID, used to build a globally unique S3 bucket name for
# ALB access logs.
data "aws_caller_identity" "current" {}

# The AWS ELB service account that writes ALB access logs to the S3 bucket.
data "aws_elb_service_account" "main" {}

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
  })

  # Minimal bootstrap: install and start httpd (listens on TCP 80), and serve a
  # simple /health endpoint so the target group HTTP health check succeeds. The
  # ALB terminates TLS on 443 and forwards to the instances on port 80.
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo 'Pulsar web tier is healthy' > /var/www/html/health
  EOF

  # S3 bucket for ALB access logs, suffixed with the account ID and environment
  # to avoid global S3 namespace collisions.
  access_logs_bucket = "pulsar-web-alb-access-logs-${data.aws_caller_identity.current.account_id}-${var.environment}"
}

resource "aws_launch_template" "web" {
  name          = "pulsar-web-launch-template"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  vpc_security_group_ids = [aws_security_group.web.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "Pulsar-web"
    })
  }

  tags = merge(local.common_tags, {
    Name = "pulsar-web-launch-template"
  })
}

resource "aws_security_group" "alb" {
  name        = "pulsar-alb-sg"
  description = "Security group for the internet-facing Pulsar web ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "pulsar-alb-sg"
  })
}

resource "aws_security_group" "web" {
  name        = "pulsar-web-sg"
  description = "Security group for the Pulsar web tier instances"
  vpc_id      = var.vpc_id

  # httpd serves on TCP 80; the ALB terminates TLS on 443 and forwards plain
  # HTTP to the instances. Only the ALB security group may reach this port.
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "pulsar-web-sg"
  })
}

resource "aws_lb_target_group" "web" {
  name        = "pulsar-web-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    path                = var.health_check_path
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 5
  }

  tags = merge(local.common_tags, {
    Name = "pulsar-web-tg"
  })
}

# S3 bucket that stores ALB access logs.
resource "aws_s3_bucket" "access_logs" {
  bucket = local.access_logs_bucket

  tags = merge(local.common_tags, {
    Name = local.access_logs_bucket
  })
}

resource "aws_s3_bucket_acl" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket                  = aws_s3_bucket.access_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = "alb/"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowELBRootAccountWrite"
        Effect    = "Allow"
        Principal = { AWS = data.aws_elb_service_account.main.arn }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.access_logs.arn}/*"
      },
      {
        Sid       = "AllowELBLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.access_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AllowELBDescribeBucket"
        Effect    = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.access_logs.arn
      }
    ]
  })
}

resource "aws_lb" "web" {
  name                       = "pulsar-web-alb"
  internal                   = false
  load_balancer_type         = "application"
  ip_address_type            = "ipv4"
  security_groups            = [aws_security_group.alb.id]
  enable_deletion_protection = true
  # The internet-facing ALB must live in the public subnets (which have a
  # route to the Internet Gateway) so it is reachable from the internet. The
  # instances themselves remain in the private subnets.
  subnets = values(var.public_subnet_ids)

  access_logs {
    bucket  = aws_s3_bucket.access_logs.id
    prefix  = "alb"
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = "pulsar-web-alb"
  })
}

resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "pulsar-web-asg"
  vpc_zone_identifier = values(var.private_subnet_ids)
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size

  launch_template {
    id = aws_launch_template.web.id
    # Use "$Default" so launch template changes are reviewed (the default
    # version is updated only on an explicit apply) before they are used for
    # new instances.
    version = "$Default"
  }

  tag {
    key                 = "Name"
    value               = "Pulsar-web-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "web" {
  name                      = "pulsar-web-cpu-tracking"
  autoscaling_group_name    = aws_autoscaling_group.web.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = var.scaling_warmup

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
