provider "aws" {
  region = "us-east-1"
}

module "lambda_role" {
  source = "./lambda_role"
}

module "lambda" {
  source = "./lambda"
  region = "us-east-1"
  role = module.lambda_role.lambda_iam_role_arn
}
