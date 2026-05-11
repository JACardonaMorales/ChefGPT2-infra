output "alb_dns_name" {
  description = "URL del balanceador de carga (punto de entrada a la API)"
  value       = aws_lb.api_alb.dns_name
}

output "rabbitmq_public_ip" {
  value = aws_instance.rabbitmq.public_ip
}

output "mongodb_public_ip" {
  value = aws_instance.mongodb.public_ip
}

output "api_instance_ips" {
  value = aws_instance.api[*].public_ip
}