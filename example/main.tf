# Example usage of the ECS NGINX module

provider "aws" {
  region = var.aws_region
}

module "ecs_nginx" {
  source           = "../modules/ecs-nginx"
  name_prefix      = var.name_prefix
  vpc_id           = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  container_port   = 80
  desired_count    = 2
  aws_region       = var.aws_region
  tags = var.tags
  nginx_conf_path  = "${path.module}/nginx.conf"
}


