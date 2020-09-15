locals {
  vpc_cidr_block = "10.0.0.0/16"
  zone_names = var.availability_zones
  number_of_zones = length(local.zone_names)
}

resource "aws_vpc" "cluster_vpc" {
  cidr_block = local.vpc_cidr_block
  tags = {
    Name = var.deployment_tag
  }
  enable_dns_support = true
  enable_dns_hostnames = true
}


resource "aws_subnet" "private_subnets" {
  count = length(local.zone_names)
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
    Type = "Private"
  }
  cidr_block = cidrsubnet(local.vpc_cidr_block, 8, count.index + 1)
  map_public_ip_on_launch = false
  availability_zone = local.zone_names[count.index]
}

resource "aws_subnet" "public_subnets" {
  count = length(local.zone_names)
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
    Type = "Public"
  }
  cidr_block = cidrsubnet(local.vpc_cidr_block, 8, length(local.zone_names) + count.index + 1)
  map_public_ip_on_launch = true
  availability_zone = local.zone_names[count.index]
}

resource "aws_eip" "elastic_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id = aws_subnet.public_subnets[0].id
}

resource "aws_route_table" "private_subnets_route_table" {
  vpc_id = aws_vpc.cluster_vpc.id

  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_route" "to_nat_gateway_route" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.private_subnets_route_table.id
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
}

resource "aws_route_table_association" "assign_private_subnets" {
  count = length(local.zone_names)
  route_table_id = aws_route_table.private_subnets_route_table.id
  subnet_id = aws_subnet.private_subnets[count.index].id
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.cluster_vpc.id
}

resource "aws_route_table" "public_subnets_route_table" {
  vpc_id = aws_vpc.cluster_vpc.id

  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_route_table_association" "assign_public_subnets" {
  count = length(local.zone_names)
  route_table_id = aws_route_table.public_subnets_route_table.id
  subnet_id = aws_subnet.public_subnets[count.index].id
}

resource "aws_route" "to_igw" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.public_subnets_route_table.id
  gateway_id = aws_internet_gateway.internet_gateway.id
}

