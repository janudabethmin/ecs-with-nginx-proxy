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

variable "aws_region" {
  description = "AWS region for resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Name for all resource names."
  type        = string
  default     = "resource"
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "desired_count" {
  description = "Number of ECS tasks to run."
  type        = number
  default     = 2
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
