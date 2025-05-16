provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "resume" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.resume.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "resume_policy" {
  bucket = aws_s3_bucket.resume.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        Resource  = "${aws_s3_bucket.resume.arn}/*"
      }
    ]
  })
}

resource "aws_s3_object" "resume_file" {
  bucket = aws_s3_bucket.resume.bucket
  key    = "resume.html"
  source = "${path.module}/../frontend/index.html"
  content_type = "text/html"
}
