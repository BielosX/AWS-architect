variable "aws_region" {}
variable "my_bucket_name" {}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "my_bucket_logs" {
  bucket = "${var.my_bucket_name}-logs"
  acl = "log-delivery-write"
  force_destroy = true
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.my_bucket_name
  acl = "private"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  logging {
    target_bucket = "${aws_s3_bucket.my_bucket_logs.id}"
  }
}

resource "aws_s3_bucket_object" "index" {
  key = "index.html"
  bucket = "${aws_s3_bucket.my_bucket.id}"
  content = "<html><body><h1>Hello World</h1></body></html>\n"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "error" {
  key = "error.html"
  bucket = "${aws_s3_bucket.my_bucket.id}"
  content = "<html><body><h1>Error</h1></body></html>\n"
  content_type = "text/html"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    actions = ["s3:GetObject"]
    effect = "Allow"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    resources = [
      "${aws_s3_bucket.my_bucket.arn}/index.html",
      "${aws_s3_bucket.my_bucket.arn}/error.html",
    ]
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  policy = "${data.aws_iam_policy_document.bucket_policy.json}"
  bucket = "${aws_s3_bucket.my_bucket.id}"
}

locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "my_bucket_distribution" {
  enabled = true

  default_cache_behavior {
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    allowed_methods = ["HEAD", "GET"]
    cached_methods = ["HEAD", "GET"]
    viewer_protocol_policy = "allow-all"
    target_origin_id = "${local.s3_origin_id}"
  }

  origin {
    domain_name = "${aws_s3_bucket.my_bucket.website_endpoint}"
    origin_id = "${local.s3_origin_id}"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.1"]
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
