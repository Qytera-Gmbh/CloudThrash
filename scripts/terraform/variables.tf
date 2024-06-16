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

variable "master_memory" {
  description = "Memory for master"
}

variable "master_cpu" {
  description = "CPU for master"
}
