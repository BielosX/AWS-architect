provider "aws" {
  region = var.region
}

module "ecs_app" {
  source = "./ecs"
  cluster_arn = var.cluster_arn
}

module "postgres" {
  source = "./postgres"
  db_subnets = var.private_subnets
  region = var.region
  vpc_id = var.vpc_id
}

module "build" {
  source = "./build"
  build_subnets = var.private_subnets
  vpc_id = var.vpc_id
}
