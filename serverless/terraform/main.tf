locals {
  region = "us-east-1"
}

provider "aws" {
  region = local.region
}

module "iam" {
  source = "./iam"
}

module "lambda_vpc" {
  source = "./vpc"
  region = local.region
}

module "books_storage" {
  source = "./storage"
  region = local.region
}

module "lambda" {
  source = "./lambda"
  region = local.region
  role = module.iam.lambda_iam_role_arn
  vpc_id = module.lambda_vpc.vpc_id
  books_bucket_name = module.books_storage.bucket_name
  subnet_ids = [
    module.lambda_vpc.first_subnet_id,
    module.lambda_vpc.second_subnet_id
  ]
}
