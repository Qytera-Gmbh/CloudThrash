# Define the security group with required rules
resource "aws_security_group" "graphite_sg" {
  name        = "graphite_sg"
  description = "Security group for Graphite ECS service"
  vpc_id      = var.vpc_id

  # Ingress rules for external access
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.security_group_id]
  }

  # Egress rules
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "graphite_sg"
  }
}

# Define the ECS Task Definition
resource "aws_ecs_task_definition" "graphite_task" {
  family                   = "graphite-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  container_definitions = jsonencode([{
    name      = "graphite"
    image     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}:graphite-latest"
    essential = true

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
  depends_on = [aws_service_discovery_service.graphite]

  name            = "graphite-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.graphite_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [aws_security_group.graphite_sg.id]
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
