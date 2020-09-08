resource "aws_vpc" "cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.deployment_tag
  }
  enable_dns_support = true
  enable_dns_hostnames = true
}

data "aws_availability_zones" "available_zones" {
  state = "available"
}

locals {
  private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets_cidr = ["10.0.3.0/24", "10.0.4.0/24"]
  zone_names = data.aws_availability_zones.available_zones.names
  number_of_zones = length(local.zone_names)
}

resource "aws_subnet" "private_subnets" {
  for_each = toset(local.private_subnets_cidr)
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
    Type = "Private"
  }
  cidr_block = each.value
  map_public_ip_on_launch = false
  availability_zone = local.zone_names[index(local.private_subnets_cidr, each.value) % local.number_of_zones]
}

resource "aws_subnet" "public_subnets" {
  for_each = toset(local.public_subnets_cidr)
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
    Type = "Public"
  }
  cidr_block = each.value
  map_public_ip_on_launch = true
  availability_zone = local.zone_names[index(local.public_subnets_cidr, each.value) % local.number_of_zones]
}

resource "aws_eip" "elastic_ip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elastic_ip.id
  subnet_id = values(aws_subnet.public_subnets)[0].id
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
  count = length(local.private_subnets_cidr)
  route_table_id = aws_route_table.private_subnets_route_table.id
  subnet_id = values(aws_subnet.private_subnets)[count.index].id
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
  count = length(local.public_subnets_cidr)
  route_table_id = aws_route_table.public_subnets_route_table.id
  subnet_id = values(aws_subnet.public_subnets)[count.index].id
}

resource "aws_route" "to_igw" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.public_subnets_route_table.id
  gateway_id = aws_internet_gateway.internet_gateway.id
}

