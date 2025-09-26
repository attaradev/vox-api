output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.app.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app.dns_name
}

output "target_group_arn" {
  description = "ARN of the Target Group"
  value       = aws_lb_target_group.app.arn
}

output "alb_ip_addresses" {
  description = "List of IP addresses for the Application Load Balancer (for DNS/domain setup)"
  value       = aws_lb.app.ip_address_type == "ipv4" ? aws_lb.app.load_balancer_addresses[*].ip_address : []
}
