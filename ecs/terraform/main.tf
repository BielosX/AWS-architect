provider "aws" {
  region = "eu-west-1"
}

locals {
  deployment_tag = "my-test-cluster"
}

module "network" {
  source = "./network"
  deployment_tag = local.deployment_tag
}

module "cluster" {
  source = "./cluster"
  cluster_name = "my-test-cluster"
  deployment_tag = local.deployment_tag
  max_instances = 2
  min_instances = 2
  subnets = module.network.private_subnets
  vpc_id = module.network.vpc_id
  key_pair = "MBIrelandKP"
}