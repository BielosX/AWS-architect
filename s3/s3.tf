variable "aws_region" {}
variable "my_bucket_name" {}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "my_bucket_logs" {
  bucket = "${var.my_bucket_name}-logs"
  acl = "log-delivery-write"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.my_bucket_name
  acl = "private"

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
  content = "<html><body><h1>Hello World</h1></body></html>"
  content_type = "text/html"
}

resource "aws_s3_bucket_object" "error" {
  key = "error.html"
  bucket = "${aws_s3_bucket.my_bucket.id}"
  content = "<html><body><h1>Error</h1></body></html>"
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
