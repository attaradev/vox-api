output "alb_arn" {
  description = "ARN of the application load balancer"
  value       = aws_lb.this.arn
}

output "alb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.this.dns_name
}

output "security_group_id" {
  description = "Security group protecting the ALB"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.app.arn
}

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = aws_lb_listener.http.arn
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener when created"
  value       = try(aws_lb_listener.https[0].arn, null)
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch dimensions"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn_suffix" {
  description = "ARN suffix of the target group"
  value       = aws_lb_target_group.app.arn_suffix
}
