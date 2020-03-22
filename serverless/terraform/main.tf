provider "aws" {
  region = "us-east-1"
}

module "iam" {
  source = "./iam"
}

module "lambda" {
  source = "./lambda"
  region = "us-east-1"
  role = module.iam.lambda_iam_role_arn
}
