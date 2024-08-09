output "ecs_cluster_name" {
  value = module.ecs.ecs_cluster_name
}

output "current_timestamp" {
  value = module.ecs.current_timestamp
}

output "grafana_admin_user" {
  value = var.grafana_admin_user
}

output "grafana_admin_password" {
  value = var.grafana_admin_password
}
