# ── 1. MongoDB ──────────────────────────────────────────────
resource "aws_instance" "mongodb" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.mongodb_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  user_data              = file("${path.module}/scripts/install_mongodb.sh")

  tags = { Name = "ChefGPT-MongoDB", Role = "NoSQLDatabase" }
}

# ── 2. RabbitMQ ─────────────────────────────────────────────
resource "aws_instance" "rabbitmq" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.rabbitmq_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  user_data              = file("${path.module}/scripts/install_rabbitmq.sh")

  tags = { Name = "ChefGPT-RabbitMQ", Role = "MessageBroker" }
}

# ── 3. Parameter Store (necesario antes de API y Worker) ─────
resource "aws_ssm_parameter" "rabbitmq_ip" {
  name        = "/chefgpt/dev/rabbitmq/public_ip"
  type        = "String"
  value       = aws_instance.rabbitmq.public_ip
  description = "IP pública de RabbitMQ"
  overwrite   = true
}

resource "aws_ssm_parameter" "mongodb_ip" {
  name        = "/chefgpt/dev/mongodb/public_ip"
  type        = "String"
  value       = aws_instance.mongodb.public_ip
  description = "IP pública de MongoDB"
  overwrite   = true
}

# ── 4. Worker ────────────────────────────────────────────────
resource "aws_instance" "worker" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.worker_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  user_data              = file("${path.module}/scripts/install_worker.sh")

  tags = { Name = "ChefGPT-Worker", Role = "AsyncWorker" }

  depends_on = [aws_ssm_parameter.rabbitmq_ip, aws_ssm_parameter.mongodb_ip]
}

# ── 5. API x2 (detrás del ALB) ──────────────────────────────
resource "aws_instance" "api" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.api_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  user_data              = file("${path.module}/scripts/install_api.sh")

  tags = { Name = "ChefGPT-API-${count.index + 1}", Role = "BackendAPI" }

  depends_on = [aws_ssm_parameter.rabbitmq_ip, aws_ssm_parameter.mongodb_ip]
}

# ── 6. Target Group ──────────────────────────────────────────
resource "aws_lb_target_group" "api_tg" {
  name     = "chefgpt-api-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "api_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.api_tg.arn
  target_id        = aws_instance.api[count.index].id
  port             = 8000
}

# ── 7. ALB ───────────────────────────────────────────────────
resource "aws_lb" "api_alb" {
  name               = "chefgpt-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  tags = { Name = "ChefGPT-ALB" }
}

resource "aws_lb_listener" "api_listener" {
  load_balancer_arn = aws_lb.api_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

# ── 8. Guardar DNS del ALB en Parameter Store ────────────────
resource "aws_ssm_parameter" "alb_dns" {
  name        = "/chefgpt/dev/alb/dns_name"
  type        = "String"
  value       = aws_lb.api_alb.dns_name
  description = "DNS público del ALB de la API"
  overwrite   = true
}
