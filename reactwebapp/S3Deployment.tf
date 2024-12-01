provider "aws" {
  region = "us-east-1"
}

# Create a new S3 bucket with website configuration
resource "aws_s3_bucket" "react_app_bucket" {
  bucket = "react-app-bucket-cloud-proj-group-02-2024"

}

resource "aws_s3_bucket_website_configuration" "react_configuration" {
    bucket = aws_s3_bucket.react_app_bucket.id

    index_document {
      suffix = "index.html"
    }

  depends_on = [ aws_s3_object.build_files ]
}


resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
    bucket = aws_s3_bucket.react_app_bucket.id

    block_public_acls       = false
    block_public_policy     = false
    ignore_public_acls      = false
    restrict_public_buckets = false
  
}

module "template_files" {
  source = "hashicorp/dir/template"

  base_dir = "./build"
}

resource "aws_s3_object" "build_files" {
  bucket = aws_s3_bucket.react_app_bucket.id

  # for_each = fileset("./build", "**/*")
  # source = "./build/${each.value}"
  # key = each.value
  # etag = filemd5("./build/${each.value}")
  key = each.key
  for_each = module.template_files.files
  source = each.value.source_path
  content_type = each.value.content_type
  content = each.value.content
  etag = each.value.digests.md5
  # acl = "public-read"
  # content_type = lookup({
  #   "html" = "text/html",
  #   "css"  = "text/css",
  #   "js"   = "application/javascript",
  #   "png"  = "image/png",
  #   "jpg"  = "image/jpeg",
  #   "jpeg" = "image/jpeg",
  #   "gif"  = "image/gif",
  #   "svg"  = "image/svg+xml",
  #   "ico"  = "image/x-icon"
  # }, split(".", each.value)[length(split(".", each.value)) - 1], "application/octet-stream")

  
}


# S3 bucket policy for public read access
resource "aws_s3_bucket_policy" "react_app_bucket_policy" {
  bucket = aws_s3_bucket.react_app_bucket.bucket

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app_bucket.arn}/*"
      },
      # {
      #   Effect    = "Allow"
      #   Principal = "*"
      #   Action    = "s3:PutObject"
      #   Resource  = "${aws_s3_bucket.react_app_bucket.arn}/*"
      # }
    ]
  })

  depends_on = [ aws_s3_object.build_files ]
}


output "website_url" {
  value = aws_s3_bucket_website_configuration.react_configuration.website_endpoint
}