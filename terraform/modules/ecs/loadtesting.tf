resource "random_id" "force_redeploy" {
  byte_length = 8
}

locals {
  current_timestamp = formatdate("YYYY-MM-DD-HH-mm", timestamp())
  unique_timestamp  = "${local.current_timestamp}-${random_id.force_redeploy.hex}"
}

resource "aws_ecs_task_definition" "task" {
  tags                     = var.common_tags
  family                   = "loadtesting-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      "name" : "loadtesting-container",
      "image" : "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}:latest",
      "essential" : true,
      "portMappings" : [
        {
          "containerPort" : 80,
          "hostPort" : 80
        }
      ],
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-group" : "/ecs/loadtesting",
          "awslogs-region" : var.aws_region,
          "awslogs-stream-prefix" : "ecs"
        }
      },
      "environment" : [
        {
          "name" : "AWS_DEFAULT_REGION",
          "value" : var.aws_region
        },
        {
          "name" : "S3_BUCKET_NAME",
          "value" : var.s3_bucket_name
        },
        {
          "name" : "TOTAL_TASKS",
          "value" : tostring(var.slave_count)
        },
        {
          "name" : "RUN_TIMESTAMP",
          "value" : local.current_timestamp
        }
      ]
    }
  ])
}

data "aws_ecs_task_execution" "loadtesting_task_execution" {
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.slave_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }
}

resource "aws_cloudwatch_log_group" "ecs_loadtesting" {
  name              = "/ecs/loadtesting"
  retention_in_days = 7
  tags              = var.common_tags
}
