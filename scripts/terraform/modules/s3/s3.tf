resource "aws_s3_bucket" "gatling_results" {
  tags   = var.common_tags
  bucket = var.s3_bucket_name

  lifecycle {
    ignore_changes = all
  }
}
