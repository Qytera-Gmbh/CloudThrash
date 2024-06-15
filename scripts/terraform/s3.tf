resource "aws_s3_bucket" "gatling_results" {
  bucket = "gatling-distributed-loadtesting-bucket"
}

resource "aws_iam_policy" "s3_access_policy" {
  name        = "ecsS3AccessPolicy"
  description = "Policy to allow ECS tasks to upload files to S3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionAcl",
          "s3:PutObjectVersionTagging"
        ]
        Resource = "arn:aws:s3:::gatling-distributed-loadtesting-bucket/gatling-results/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}
