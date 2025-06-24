output "alb_dns_name" {
  value = module.ecs_nginx.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.ecs_nginx.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.ecs_nginx.ecs_service_name
}
