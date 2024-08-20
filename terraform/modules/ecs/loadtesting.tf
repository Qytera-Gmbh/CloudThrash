resource "random_id" "force_redeploy" {
  byte_length = 8
}

locals {
  current_timestamp = formatdate("YYYY-MM-DD-HH-mm", timestamp())
  unique_timestamp  = "${local.current_timestamp}-${random_id.force_redeploy.hex}"
  s3_prefix         = "gatling-results/${var.user}/${var.app_name}/${local.unique_timestamp}"
}

resource "aws_ecs_task_definition" "task" {
  tags                     = merge(var.common_tags, { "user" = var.user, "app_name" = var.app_name, "unique_timestamp" = local.unique_timestamp, "is_leader" = "false" })
  family                   = "loadtesting-task-agent-${local.unique_timestamp}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      "stopTimeout" : 10,
      "name" : "loadtesting-container",
      "image" : "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}:gatling-latest",
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
          "value" : "${var.s3_bucket_name}"
        },
        {
          "name" : "S3_PREFIX",
          "value" : local.s3_prefix
        },
        {
          "name" : "TOTAL_TASKS",
          "value" : tostring(var.slave_count)
        },
        {
          "name" : "TELEGRAF_PREFIX",
          "value" : "telegraf.${var.user}.${var.app_name}"
        },
        {
          "name" : "GATLING_PREFIX",
          "value" : "gatling.${var.user}.${var.app_name}"
        },
        {
          "name" : "IS_LEADER",
          "value" : "false"
        }
      ]
    }
  ])

  depends_on = [aws_ecs_service.graphite_service, aws_service_discovery_private_dns_namespace.loadtest]
}

resource "aws_ecs_task_definition" "task_leader" {
  tags                     = merge(var.common_tags, { "user" = var.user, "app_name" = var.app_name, "unique_timestamp" = local.unique_timestamp, "is_leader" = "true" })
  family                   = "loadtesting-task-leader-${local.unique_timestamp}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.slave_cpu
  memory                   = var.slave_memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      "stopTimeout" : 10,
      "name" : "loadtesting-container",
      "image" : "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repository}:gatling-latest",
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
          "value" : "${var.s3_bucket_name}"
        },
        {
          "name" : "S3_PREFIX",
          "value" : local.s3_prefix
        },
        {
          "name" : "UNIQUE_TIMESTAMP",
          "value" : local.unique_timestamp
        },
        {
          "name" : "TOTAL_TASKS",
          "value" : tostring(var.slave_count)
        },
        {
          "name" : "TELEGRAF_PREFIX",
          "value" : "telegraf.${var.user}.${var.app_name}"
        },
        {
          "name" : "GATLING_PREFIX",
          "value" : "gatling.${var.user}.${var.app_name}"
        },
        {
          "name" : "IS_LEADER",
          "value" : "true"
        }
      ]
    }
  ])

  depends_on = [aws_ecs_service.graphite_service, aws_service_discovery_private_dns_namespace.loadtest]
}

data "aws_ecs_task_execution" "loadtesting_task_execution" {
  count = var.slave_count - 1

  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_service.graphite_service, aws_service_discovery_private_dns_namespace.loadtest]
  tags       = merge(var.common_tags, { "user" = var.user, "app_name" = var.app_name, "unique_timestamp" = local.unique_timestamp, "is_leader" = "false" })
}

data "aws_ecs_task_execution" "loadtesting_task_execution_leader" {
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_leader.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  depends_on = [aws_ecs_service.graphite_service, aws_service_discovery_private_dns_namespace.loadtest]
  tags       = merge(var.common_tags, { "user" = var.user, "app_name" = var.app_name, "unique_timestamp" = local.unique_timestamp, "is_leader" = "true" })
}

resource "aws_cloudwatch_log_group" "ecs_loadtesting" {
  name              = "/ecs/loadtesting"
  retention_in_days = 7
  tags              = var.common_tags
}
