variable "aws_region" {
  description = "AWS region"
}

variable "aws_profile" {
  description = "AWS profile"
}

variable "aws_account_id" {
  description = "AWS account ID"
}

variable "ecr_repository" {
  description = "ECR repository name"
}

variable "s3_bucket_name" {
  description = "S3 bucket name"
}

variable "slave_memory" {
  description = "Memory for slave"
}

variable "slave_cpu" {
  description = "CPU for slave"
}

variable "slave_count" {
  description = "Number of slaves"
}

variable "common_tags" {
  default = {
    Project = "LoadTesting"
  }
}

variable "grafana_admin_user" {
  description = "Grafana admin user"
}

variable "grafana_admin_password" {
  description = "Grafana admin password"
}

variable "user" {
  description = "User"
}

variable "app_name" {
  description = "App name"
  default     = "BasicSimulation"
}

variable "env_vars" {
  description = "Environment variables"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
}
