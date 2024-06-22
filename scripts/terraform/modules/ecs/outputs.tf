output "ecs_cluster_name" {
  value = aws_ecs_cluster.ecs_cluster.name
}

output "slave_count" {
  value = var.slave_count
}
