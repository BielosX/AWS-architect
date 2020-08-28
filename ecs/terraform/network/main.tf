resource "aws_vpc" "cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.deployment_tag
  }
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

locals {
  subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  zone_names = data.aws_availability_zones.available_zones.names
  number_of_zones = length(local.zone_names)
}

resource "aws_subnet" "private_subnets" {
  for_each = toset(local.subnets_cidr)
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
  }
  cidr_block = each.value
  map_public_ip_on_launch = false
  availability_zone = local.zone_names[index(local.subnets_cidr, each.value) % local.number_of_zones]
}
