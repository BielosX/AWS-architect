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

resource "aws_security_group" "lambda_security_group" {
  name = "lambda_security_group"
  vpc_id = var.vpc_id
}

resource "aws_lambda_function" "my_lambda" {
  s3_bucket = "${aws_s3_bucket.lambda_bucket.id}"
  s3_key = "${aws_s3_bucket_object.lambda_init_archive.key}"
  function_name = "books_lambda"
  handler = "main.main"
  role = var.role
  runtime = "python3.7"
  environment {
    variables = {
      BUCKET_NAME = var.books_bucket_name
    }
  }
  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_security_group.lambda_security_group.id]
  }
}

resource "aws_lambda_permission" "lambda_permission" {
  statement_id = "AllowExecutionFromApiGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda.function_name
  principal = "apigateway.amazonaws.com"
}
