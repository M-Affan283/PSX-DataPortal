# S3 Bucket
resource "aws_s3_bucket" "pdf_bucket" {
  bucket = "s3bucket-psx-dataportal-clouddev-project-group02"
  force_destroy = true
}
