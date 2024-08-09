resource "aws_ecs_task_definition" "grafana_task" {
  family                   = "grafana-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  container_definitions = jsonencode([{
    name      = "grafana"
    image     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}:grafana-latest"
    essential = true

    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "GF_SECURITY_ADMIN_PASSWORD"
        value = "${var.grafana_admin_password}"
      },
      {
        name  = "GF_SECURITY_ADMIN_USER"
        value = "${var.grafana_admin_user}"
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/grafana"
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "grafana_service" {
  depends_on = [aws_ecs_service.graphite_service]

  name            = "grafana-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.grafana_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_log_group" "grafana_log_group" {
  name              = "/ecs/grafana"
  retention_in_days = 7
}
