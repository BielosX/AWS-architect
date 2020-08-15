provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "initial_code" {
  bucket = aws_s3_bucket.lambda_bucket.id
  key = var.jar_file_name
  source = var.jar_file_path
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_iam_role" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

resource "aws_lambda_function" "lambda_sns" {
  depends_on = [aws_s3_bucket_object.initial_code]
  function_name = var.lambda_name
  handler = var.lambda_handler
  role = aws_iam_role.lambda_iam_role.arn
  runtime = "java11"
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = var.jar_file_name
}