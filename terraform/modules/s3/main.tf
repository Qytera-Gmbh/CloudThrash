resource "aws_iam_policy" "s3_bucket_management" {
  tags        = var.common_tags
  name        = "s3-bucket-management"
  description = "Policy to manage S3 bucket, including deletion of objects"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "terraform_role" {
  tags = var.common_tags
  name = "terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.terraform_role.name
  policy_arn = aws_iam_policy.s3_bucket_management.arn
}

resource "aws_s3_bucket" "gatling_results" {
  tags          = var.common_tags
  bucket        = var.s3_bucket_name
  force_destroy = true
}
