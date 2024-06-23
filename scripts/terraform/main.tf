provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "ecs" {
  source         = "./modules/ecs"
  aws_region     = var.aws_region
  aws_profile    = var.aws_profile
  aws_account_id = var.aws_account_id
  ecr_repository = var.ecr_repository
  slave_memory   = var.slave_memory
  slave_cpu      = var.slave_cpu
  slave_count    = var.slave_count
  master_memory  = var.master_memory
  master_cpu     = var.master_cpu
  s3_bucket_name = var.s3_bucket_name
  common_tags    = var.common_tags
}

module "s3" {
  source         = "./modules/s3"
  s3_bucket_name = var.s3_bucket_name
  common_tags    = var.common_tags
}

terraform {
  backend "local" {
    path = ".terraform/tfstates/terraform.tfstate"
  }
}
