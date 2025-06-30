# ECS NGINX Module - variables.tf

variable "name_prefix" {
  description = "Prefix for all resource names."
  type        = string
  default     = "resource"
}

variable "vpc_id" {
  description = "The VPC ID to deploy resources into."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB."
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "nginx_conf_path" {
  description = "Path to the local nginx.conf file to use. Defaults to the module's bundled nginx.conf (relative to the module)."
  type        = string
  default     = "nginx.conf"
}

variable "container_port" {
  description = "Port NGINX listens on."
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Number of ECS tasks to run."
  type        = number
  default     = 1
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "hosted_zone_name" {
  description = "(Optional) Route 53 hosted zone name for DNS/HTTPS setup. If set, ACM certificate, HTTPS listener, and DNS record will be created."
  type        = string
  default     = null
}

variable "hosted_zone_name_prefix" {
  description = "(Optional) Prefix for the DNS record in the hosted zone, e.g. 'app' for app.mydomain.com. Defaults to 'nginx' if not set."
  type        = string
  default     = "nginx"
}
