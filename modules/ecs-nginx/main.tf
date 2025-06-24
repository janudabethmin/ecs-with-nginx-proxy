# ECS NGINX Module - main.tf

# --- ECS Cluster ---
resource "aws_ecs_cluster" "this" {
  name = format("%s-%s-ecs-cluster", var.name_prefix, random_id.suffix.hex)
  tags = var.tags
}

# --- S3 Bucket for nginx.conf ---
resource "aws_s3_bucket" "nginx_conf" {
  bucket = format("%s-%s-nginx-conf", var.name_prefix, random_id.suffix.hex)
  force_destroy = true
  tags = var.tags
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_object" "nginx_conf" {
  bucket       = aws_s3_bucket.nginx_conf.bucket
  key          = "nginx.conf"
  source       = var.nginx_conf_path
  content_type = "text/plain"
  tags         = var.tags
  etag         = filemd5(var.nginx_conf_path)
}

# --- IAM Role for ECS Task to access S3 ---
resource "aws_iam_role" "task_execution" {
  name = "ecsTaskExecutionRole-nginx"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
  tags = var.tags
}

data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "s3_read_nginx_conf" {
  name        = "nginx-conf-read-policy"
  description = "Allow ECS task to read nginx.conf from S3"
  policy      = data.aws_iam_policy_document.s3_read.json
  tags        = var.tags
}

data "aws_iam_policy_document" "s3_read" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.nginx_conf.arn}/*"]
  }
}

resource "aws_iam_role_policy_attachment" "s3_read_attach" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.s3_read_nginx_conf.arn
}

# --- Security Groups ---
resource "aws_security_group" "alb" {
  name        = format("%s-%s-alb-sg", var.name_prefix, random_id.suffix.hex)
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_service" {
  name        = format("%s-%s-ecs-service-sg", var.name_prefix, random_id.suffix.hex)
  description = "Allow traffic from ALB"
  vpc_id      = var.vpc_id
  tags        = var.tags

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- ALB ---
resource "aws_lb" "this" {
  name               = format("%s-%s-alb", var.name_prefix, random_id.suffix.hex)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = false
  tags = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = format("%s-%s-tg", var.name_prefix, random_id.suffix.hex)
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  tags        = var.tags
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# --- ECS Task Definition ---
resource "aws_ecs_task_definition" "nginx" {
  family                   = format("%s-%s-nginx", var.name_prefix, random_id.suffix.hex)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "public.ecr.aws/nginx/nginx:latest"
      entryPoint = ["/bin/sh", "-c"]
      command = [
        "set -ex && apt-get update && apt-get install -y awscli && echo 'ENV:' && env && echo 'Downloading nginx.conf from S3...' && aws s3 cp s3://$NGINX_CONF_BUCKET/$NGINX_CONF_KEY /etc/nginx/nginx.conf || { echo 'S3 download failed!'; exit 1; } && echo '--- /etc/nginx/nginx.conf content ---' && cat /etc/nginx/nginx.conf && echo '--- end nginx.conf ---' && echo 'Validating nginx.conf syntax...' && nginx -t -c /etc/nginx/nginx.conf || { echo 'nginx.conf syntax invalid!'; exit 1; } && echo 'Tailing nginx logs...' && (tail -F /var/log/nginx/access.log /var/log/nginx/error.log &) && echo 'Starting nginx...' && nginx -g 'daemon off;'"
      ]
      environment = [
        { name = "NGINX_CONF_BUCKET", value = "${aws_s3_bucket.nginx_conf.bucket}" },
        { name = "NGINX_CONF_KEY", value = "nginx.conf" }
      ]
      portMappings = [{
        containerPort = var.container_port
        protocol      = "tcp"
      }]
      essential = true
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = format("/ecs/%s-%s-nginx", var.name_prefix, random_id.suffix.hex)
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  # No volumes or mountPoints needed for Fargate
}

# --- EFS for nginx.conf (mounted by ECS) ---
resource "aws_efs_file_system" "nginx_conf" {
  creation_token = format("%s-%s-nginx-conf-efs", var.name_prefix, random_id.suffix.hex)
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "nginx_conf" {
  for_each = toset(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.nginx_conf.id
  subnet_id       = each.value
  security_groups = [aws_security_group.ecs_service.id]
}

resource "aws_efs_access_point" "nginx_conf" {
  file_system_id = aws_efs_file_system.nginx_conf.id
  posix_user {
    gid = 0
    uid = 0
  }
  root_directory {
    path = "/"
    creation_info {
      owner_gid   = 0
      owner_uid   = 0
      permissions = "755"
    }
  }
}

# --- ECS Service ---
resource "aws_ecs_service" "this" {
  name            = format("%s-%s-nginx-service", var.name_prefix, random_id.suffix.hex)
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.nginx.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count
  tags            = var.tags

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 300
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_service.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "nginx"
    container_port   = var.container_port
  }
  depends_on = [aws_lb_listener.this]
}

# --- CloudWatch Log Group ---
resource "aws_cloudwatch_log_group" "nginx" {
  name              = format("/ecs/%s-%s-nginx", var.name_prefix, random_id.suffix.hex)
  retention_in_days = 7
  tags              = var.tags
}

# --- AWS Region Variable ---
variable "aws_region" {
  description = "AWS region for resources."
  type        = string
  default     = "us-east-1"
}

# --- Force ECS Deploy on nginx.conf Change ---
resource "null_resource" "force_ecs_deploy_on_nginx_conf_change" {
  triggers = {
    nginx_conf_etag = aws_s3_object.nginx_conf.etag
  }

  provisioner "local-exec" {
    command = "aws ecs update-service --cluster ${aws_ecs_cluster.this.name} --service ${aws_ecs_service.this.name} --force-new-deployment --region ${var.aws_region}"
  }
}
