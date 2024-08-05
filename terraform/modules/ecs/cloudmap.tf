resource "aws_service_discovery_private_dns_namespace" "loadtest" {
  name        = "loadtest"
  vpc         = var.vpc_id
  description = "Private DNS namespace for ECS services"
}

resource "aws_service_discovery_service" "graphite" {
  depends_on = [aws_service_discovery_private_dns_namespace.loadtest]

  name = "graphite"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.loadtest.id

    dns_records {
      type = "A"
      ttl  = 60
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}
