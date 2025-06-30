provider "aws" {
  region = var.aws_region
}

module "ecs_nginx" {
  source             = "../modules/ecs-nginx"
  name_prefix        = var.name
  vpc_id             = var.vpc_id
  public_subnet_ids  = var.public_subnet_ids
  private_subnet_ids = var.private_subnet_ids
  container_port     = 80
  desired_count      = var.desired_count
  aws_region         = var.aws_region
  tags               = var.tags
  nginx_conf_path    = "${path.module}/nginx.conf"
  hosted_zone_name = var.hosted_zone_name
  hosted_zone_name_prefix = var.hosted_zone_name_prefix
}


