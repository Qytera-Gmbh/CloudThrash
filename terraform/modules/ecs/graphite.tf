resource "aws_ecs_task_definition" "graphite_task" {
  family                   = "graphite-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  container_definitions = jsonencode([{
    name      = "graphite"
    image     = "graphiteapp/graphite-statsd:latest"
    essential = true

    portMappings = [{
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "GRAPHITE_STORAGE_DIR"
        value = "/opt/graphite/storage"
      },
      {
        name  = "GRAPHITE_TIME_ZONE"
        value = "UTC"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/graphite"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "graphite_service" {
  name            = "graphite-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.graphite_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.graphite.arn
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/graphite"
  retention_in_days = 7
}
