output "app_endpoint" {
  description = "The endpoint of the web application"
  value       = aws_lb.this.dns_name
}

output "bastion" {
  description = "The ip address of the bastion host"
  value       = aws_instance.bastion.public_ip
}
