provider "aws" {
  region = var.region
}

# Section: S3 Bucket

resource "aws_s3_bucket" "resume" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.resume.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "resume_file" {
  bucket = aws_s3_bucket.resume.bucket
  key    = "resume.html"
  source = "${path.module}/../frontend/index.html"
  content_type = "text/html"
}

# Section: Cloudfront

resource "aws_cloudfront_origin_access_control" "resume" {
  name                              = "resume-cloudfront-oac"
  description                       = "OAC for private resume html S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 3. CloudFront Distribution
locals {
  s3_origin_id = "S3Origin"
}
resource "aws_cloudfront_distribution" "resume" {
  origin {
    domain_name = "${aws_s3_bucket.resume.bucket}.s3.${var.region}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.resume.id
    origin_id   = local.s3_origin_id
  }

  aliases = ["urielc.com"]
  enabled             = true
  default_root_object = "resume.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

data "aws_iam_policy_document" "cloudfront_access" {
  statement {
    sid    = "AllowCloudFrontAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.resume.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.resume.arn]
    }
  }
}

# Linking the cloudfront access policy to the s3 bucket
resource "aws_s3_bucket_policy" "resume_policy" {
  bucket = aws_s3_bucket.resume.id
  policy = data.aws_iam_policy_document.cloudfront_access.json
}