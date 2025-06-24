# ECS-TF: Terraform Template for ECS with NGINX

> **This is the only open source template for deploying containerized workloads on AWS ECS with NGINX as the reverse proxy, using Terraform. Feel free to use, modify, and share!**


This repository provides an example of using Terraform to deploy an NGINX service on AWS ECS (Elastic Container Service). It includes reusable modules and a sample configuration for quick setup and experimentation.

## Features
- **Modular Design**: Easily reusable ECS module for running NGINX or other containerized services.
- **Sample Usage**: Example configuration and variables for rapid deployment.
- **Custom NGINX Config**: Override default NGINX settings with your own `nginx.conf`.

## Getting Started
1. **Clone the repository**
   ```sh
   git clone <this-repo-url>
   cd ecs-tf/example
   ```
2. **Initialize Terraform**
   ```sh
   terraform init
   ```
3. **Review and update variables**
   - Edit `terraform.tfvars` to set your AWS region, VPC, subnets, and other required parameters.
4. **Apply the configuration**
   ```sh
   terraform apply
   ```

## Requirements
- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- AWS account credentials configured (via environment variables or AWS CLI)

## Customization
- Modify `nginx.conf` in the `example/` directory to change NGINX behavior.
- The module in `modules/ecs-nginx/` can be adapted for other container images or services.

## Example `terraform.tfvars`
Below is a sample `terraform.tfvars` file with demo data. Replace the values with your actual AWS resource IDs and preferences:

```hcl
vpc_id             = "vpc-12345678"
public_subnet_ids  = ["subnet-11111111", "subnet-22222222"] 
private_subnet_ids = ["subnet-33333333", "subnet-44444444"] 
aws_region         = "us-east-1"
name        = "demo-ecs-nginx"
tags = {
  "Name"        = "demo-ecs-nginx"
  "Environment" = "dev"
  "Project"     = "ecs-demo"
}
```

## Cleaning Up
To destroy the created resources:
```sh
terraform destroy
```

## License
MIT License. See [LICENSE](LICENSE) for details.

---
_Last updated: 2025-06-24_
