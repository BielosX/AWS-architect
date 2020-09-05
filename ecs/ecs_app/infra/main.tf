provider "aws" {
  region = var.region
}

module "load_balancer" {
  source = "./loadbalancer"
  public_subnets = var.public_subnets
  vpc_id = var.vpc_id
}

module "ecs_app" {
  source = "./ecs"
  cluster_name = var.cluster_name
  lb_target_group = module.load_balancer.target_group_arn
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
