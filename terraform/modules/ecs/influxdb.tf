resource "aws_ecs_task_definition" "influxdb_task" {
  family                   = "influxdb-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  container_definitions = jsonencode([{
    name      = "influxdb"
    image     = "influxdb:latest"
    essential = true

    portMappings = [{
      containerPort = 8086
      hostPort      = 8086
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "INFLUXDB_HTTP_BIND_ADDRESS"
        value = ":8086"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_MODE"
        value = "setup"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_USERNAME"
        value = "admin"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_PASSWORD"
        value = "password"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_ORG"
        value = "loadtesting"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_BUCKET"
        value = "loadtesting"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_RETENTION"
        value = "1w"
      },
      {
        name  = "DOCKER_INFLUXDB_INIT_ADMIN_TOKEN"
        value = "my-secret-token"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/influxdb"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "influxdb_service" {
  name            = "influxdb-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.influxdb_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.influxdb.arn
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/influxdb"
  retention_in_days = 7
}
