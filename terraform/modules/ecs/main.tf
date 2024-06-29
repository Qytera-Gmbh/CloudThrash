resource "aws_ecs_cluster" "ecs_cluster" {
  name = "loadtesting-cluster"
  tags = var.common_tags
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  tags = var.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

locals {
  current_timestamp = formatdate("YYYY-MM-DD-HH-mm", timestamp())
}

resource "null_resource" "force_redeploy" {
  triggers = {
    timestamp = local.current_timestamp
  }
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"
  tags = var.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  ]
}

resource "aws_ecs_service" "service" {
  tags            = var.common_tags
  name            = "loadtesting-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.slave_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [var.subnet_id]
    security_groups  = [var.security_group_id]
    assign_public_ip = true
  }

  depends_on = [null_resource.force_redeploy]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "ecsS3AccessPolicy"
  description = "Policy to allow ECS tasks to upload files to S3"
  tags        = var.common_tags

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionAcl",
          "s3:PutObjectVersionTagging"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/gatling-results/*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "ecs_loadtesting" {
  name              = "/ecs/loadtesting"
  retention_in_days = 7
  tags              = var.common_tags
}
