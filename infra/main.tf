provider "aws" {
  region = var.region
}

provider "aws" {
  alias = "us_east_1"
  region = "us-east-1"
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

# Section: certificate

resource "aws_acm_certificate" "cert" {
  provider = aws.us_east_1
  domain_name       = "urielc.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
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
    ssl_support_method = "sni-only"
    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
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

# Section: dns

data "aws_route53_zone" "primary" {
  name = "urielc.com"
}

resource "aws_route53_record" "root" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "urielc.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.resume.domain_name
    zone_id                = aws_cloudfront_distribution.resume.hosted_zone_id
    evaluate_target_health = false
  }
}
