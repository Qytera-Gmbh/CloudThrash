output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "slave_count" {
  value = var.slave_count
}

output "unique_timestamp" {
  value = local.unique_timestamp
}

output "s3_prefix" {
  value = local.s3_prefix
}

output "grafana_admin_user" {
  value = var.grafana_admin_user
}

output "grafana_admin_password" {
  value = var.grafana_admin_password
}
