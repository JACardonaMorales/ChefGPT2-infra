output "alb_dns_name" {
  description = "URL del balanceador de carga (punto de entrada a la API)"
  value       = aws_lb.api_alb.dns_name
}

output "rabbitmq_public_ip" {
  description = "IP pública de RabbitMQ (solo para SSH de diagnóstico)"
  value       = aws_instance.rabbitmq.public_ip
}

output "rabbitmq_private_ip" {
  description = "IP privada de RabbitMQ (usada por API y Worker internamente)"
  value       = aws_instance.rabbitmq.private_ip
}

output "mongodb_public_ip" {
  description = "IP pública de MongoDB (solo para SSH de diagnóstico)"
  value       = aws_instance.mongodb.public_ip
}

output "mongodb_private_ip" {
  description = "IP privada de MongoDB (usada por API y Worker internamente)"
  value       = aws_instance.mongodb.private_ip
}

output "worker_public_ip" {
  description = "IP pública del Worker (solo para SSH de diagnóstico)"
  value       = aws_instance.worker.public_ip
}

output "api_instance_ips" {
  description = "IPs públicas de las instancias API (solo para SSH de diagnóstico)"
  value       = aws_instance.api[*].public_ip
}