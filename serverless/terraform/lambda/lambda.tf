variable "region" {
  type = string
}

variable "role" {}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = "bielosx-lambda-bucket-${var.region}"
  acl = "private"
  force_destroy = true
}

data "archive_file" "lambda_init" {
  type = "zip"
  output_path = "${path.module}/lambda.zip"
  source {
    filename = "main.py"
    content = <<-EOT
    def main(event, context):
      return {'statusCode':200, 'body': "Hello"}
    EOT
  }
}

resource "aws_s3_bucket_object" "lambda_init_archive" {
  bucket = "${aws_s3_bucket.lambda_bucket.id}"
  key = "lambda.zip"
  source = "${data.archive_file.lambda_init.output_path}"
}

resource "aws_lambda_function" "my_lambda" {
  s3_bucket = "${aws_s3_bucket.lambda_bucket.id}"
  s3_key = "${aws_s3_bucket_object.lambda_init_archive.key}"
  function_name = "books_lambda"
  handler = "main.main"
  role = var.role
  runtime = "python3.7"
}
