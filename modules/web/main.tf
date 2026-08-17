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

locals {
  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
  })

  # Minimal bootstrap: install and start httpd, and serve a simple /health
  # endpoint so the target group health check succeeds.
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo 'Pulsar web tier is healthy' > /var/www/html/health
  EOF
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

  ingress {
    from_port       = 443
    to_port         = 443
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
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTPS"
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

resource "aws_lb" "web" {
  name               = "pulsar-web-alb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.alb.id]
  subnets            = values(var.private_subnet_ids)

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
    id      = aws_launch_template.web.id
    version = "$Latest"
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
  name                   = "pulsar-web-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
