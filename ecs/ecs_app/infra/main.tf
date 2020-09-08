provider "aws" {
  region = var.region
}

data "aws_subnet_ids" "public_subnets" {
  vpc_id = var.vpc_id
  filter {
    name = "tag:Type"
    values = ["Public"]
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = var.vpc_id
  filter {
    name = "tag:Type"
    values = ["Private"]
  }
}

module "load_balancer" {
  source = "./loadbalancer"
  vpc_id = var.vpc_id
  public_subnets = data.aws_subnet_ids.public_subnets
}

module "ecs_app" {
  source = "./ecs"
  cluster_name = var.cluster_name
  lb_target_group = module.load_balancer.target_group_arn
}

module "postgres" {
  source = "./postgres"
  region = var.region
  vpc_id = var.vpc_id
  db_subnets = data.aws_subnet_ids.private_subnets
}

module "build" {
  source = "./build"
  vpc_id = var.vpc_id
  build_subnets = data.aws_subnet_ids.private_subnets
}
