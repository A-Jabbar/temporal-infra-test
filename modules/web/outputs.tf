output "alb_id" {
  description = "ID of the Pulsar web ALB"
  value       = aws_lb.web.id
}

output "alb_dns_name" {
  description = "DNS name of the Pulsar web ALB"
  value       = aws_lb.web.dns_name
}

output "alb_arn" {
  description = "ARN of the Pulsar web ALB"
  value       = aws_lb.web.arn
}

output "target_group_arn" {
  description = "ARN of the Pulsar web target group"
  value       = aws_lb_target_group.web.arn
}

output "asg_id" {
  description = "ID of the Pulsar web Auto Scaling Group"
  value       = aws_autoscaling_group.web.id
}

output "launch_template_id" {
  description = "ID of the Pulsar web launch template"
  value       = aws_launch_template.web.id
}

output "web_sg_id" {
  description = "ID of the Pulsar web instance security group"
  value       = aws_security_group.web.id
}

output "alb_sg_id" {
  description = "ID of the Pulsar web ALB security group"
  value       = aws_security_group.alb.id
}
