# ChefGPT2-infra

Infraestructura como código para el sistema de logging distribuido ChefGPT2, aprovisionada con OpenTofu (Terraform) en AWS.

## Repositorio de la aplicación
https://github.com/JACardonaMorales/ChefGPT2-app

## Despliegue

```bash
tofu init
tofu plan
tofu apply
```

## Recursos desplegados (18)
- EC2: MongoDB, RabbitMQ, Worker, API ×2
- Application Load Balancer + Target Group
- SSM Parameter Store (IPs y DNS del ALB)
- Security Groups por componente
