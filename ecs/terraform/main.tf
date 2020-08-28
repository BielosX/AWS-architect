provider "aws" {
  region = "eu-west-1"
}

module "cluster" {
  source = "./cluster"
  cluster_name = "my-test-cluster"
  deployment_tag = "my-test-cluster"
  max_instances = 2
  min_instances = 2
  subnets = ["subnet-09363209ceb110bce"]
  vpc_id = "vpc-0c147fd489a997a6a"
  key_pair = "MBIrelandKP"
}