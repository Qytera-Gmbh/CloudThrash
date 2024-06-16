resource "aws_s3_bucket" "gatling_results" {
  bucket = var.s3_bucket_name

  lifecycle {
    ignore_changes = all
  }
}
