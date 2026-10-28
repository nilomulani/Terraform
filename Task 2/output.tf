output "elb_dns_name" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.main_lb.dns_name
}