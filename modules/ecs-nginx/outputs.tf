# ECS NGINX Module - outputs.tf

output "alb_dns_name" {
  description = "The DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_fqdn" {
  description = "The FQDN (custom DNS name) for the ALB, if HTTPS/DNS is enabled."
  value       = var.hosted_zone_name != null ? local.fqdn : null
}

output "nginx_conf_etag" {
  description = "ETag of the nginx.conf S3 object. Use as a trigger for forced ECS redeployments."
  value       = aws_s3_object.nginx_conf.etag
}

output "ecs_cluster_name" {
  description = "ECS Cluster name."
  value       = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "ECS Service name."
  value       = aws_ecs_service.this.name
}
