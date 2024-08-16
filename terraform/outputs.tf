output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

output "unique_timestamp" {
  value = module.ecs.unique_timestamp
}

output "s3_prefix" {
  value = module.ecs.s3_prefix
}

output "grafana_admin_user" {
  value = var.grafana_admin_user
}

output "grafana_admin_password" {
  value = var.grafana_admin_password
}
