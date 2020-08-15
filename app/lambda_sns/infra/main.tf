provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket" "lambda_output_bucket" {
  bucket = "lambda-output-bucket-${var.aws_region}"
  force_destroy = true
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

resource "aws_iam_role_policy_attachment" "attach_s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role = aws_iam_role.lambda_iam_role.name
}

resource "aws_iam_role_policy_attachment" "attach_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role = aws_iam_role.lambda_iam_role.name
}

resource "aws_sns_topic" "lambda_trigger_topic" {
  name = "lambda-trigger-topic-${var.aws_region}"
}

resource "aws_lambda_function" "lambda_sns" {
  depends_on = [aws_s3_bucket_object.initial_code]
  function_name = var.lambda_name
  handler = var.lambda_handler
  role = aws_iam_role.lambda_iam_role.arn
  runtime = "java11"
  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key = var.jar_file_name
  timeout = 120
  memory_size = 512
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambda_output_bucket.id
      REGION = var.aws_region
    }
  }
}

resource "aws_sns_topic_subscription" "lambda_topic_sub" {
  endpoint = aws_lambda_function.lambda_sns.arn
  protocol = "lambda"
  topic_arn = aws_sns_topic.lambda_trigger_topic.arn
}

resource "aws_lambda_permission" "allow_sns_to_invoke_lambda" {
  statement_id = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_sns.function_name
  principal = "sns.amazonaws.com"
}