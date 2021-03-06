provider "aws" {
  region = "eu-west-1"
}

locals {
  deployment_tag = "my-test-cluster"
  availability_zones = [
    "eu-west-1a",
    "eu-west-1b",
    "eu-west-1c"
  ]
}

module "network" {
  source = "./network"
  deployment_tag = local.deployment_tag
  availability_zones = local.availability_zones
}

module "security" {
  source = "./security"
  deployment_tag = local.deployment_tag
  vpc_id = module.network.vpc_id
}

module "nfs" {
  source = "./nfs"
  availability_zones = local.availability_zones
  private_subnets = module.network.private_subnets
  vpc_id = module.network.vpc_id
  mount_target_sg = module.security.mount_target_security_group
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
  docker_volumes_fs_id = module.nfs.docker_volumes_fs_id
  cluster_security_group = module.security.cluster_security_group
}
