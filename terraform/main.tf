provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

module "ecs" {
  source                 = "./modules/ecs"
  aws_region             = var.aws_region
  aws_profile            = var.aws_profile
  aws_account_id         = var.aws_account_id
  ecr_repository         = var.ecr_repository
  slave_memory           = var.slave_memory
  slave_cpu              = var.slave_cpu
  slave_count            = var.slave_count
  s3_bucket_name         = var.s3_bucket_name
  common_tags            = var.common_tags
  subnet_id              = module.network.subnet_id
  security_group_id      = module.network.security_group_id
  vpc_id                 = module.network.vpc_id
  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
}

module "s3" {
  source         = "./modules/s3"
  s3_bucket_name = var.s3_bucket_name
  common_tags    = var.common_tags
}

module "network" {
  source      = "./modules/network"
  aws_region  = var.aws_region
  common_tags = var.common_tags
}

terraform {
  backend "local" {
    path = ".terraform/tfstates/terraform.tfstate"
  }
}
