resource "aws_cloudwatch_log_group" "ecs_loadtesting" {
  name              = "/ecs/loadtesting"
  retention_in_days = 7
}
