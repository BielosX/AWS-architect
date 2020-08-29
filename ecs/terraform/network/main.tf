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
  subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24"]
  zone_names = data.aws_availability_zones.available_zones.names
  number_of_zones = length(local.zone_names)
  region_name = data.aws_region.current.name
  ecs_endpoints = [
    "com.amazonaws.${local.region_name}.ecs-agent",
    "com.amazonaws.${local.region_name}.ecs-telemetry",
    "com.amazonaws.${local.region_name}.ecs"
  ]
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

data "aws_region" "current" {}

data "aws_iam_policy_document" "ecr_s3_permission" {
  statement {
    actions = ["s3:GetObject"]
    effect = "Allow"
    resources = ["arn:aws:s3:::prod-${local.region_name}-starport-layer-bucket/*"]
    principals {
      identifiers = ["*"]
      type = "*"
    }
  }
}

resource "aws_route_table" "private_subnets_route_table" {
  vpc_id = aws_vpc.cluster_vpc.id

  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_route_table_association" "assign_private_subnets" {
  count = length(local.subnets_cidr)
  route_table_id = aws_route_table.private_subnets_route_table.id
  subnet_id = aws_subnet.private_subnets[element(local.subnets_cidr, count.index)].id
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_id = aws_vpc.cluster_vpc.id
  vpc_endpoint_type = "Gateway"
  policy = data.aws_iam_policy_document.ecr_s3_permission.json
  route_table_ids = [aws_route_table.private_subnets_route_table.id]

  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_security_group" "vpc_interface_security_group" {
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
  }
  ingress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 443
    protocol = "tcp"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "ecs_endpoints" {
  for_each = toset(local.ecs_endpoints)

  service_name = each.value
  vpc_id = aws_vpc.cluster_vpc.id
  vpc_endpoint_type = "Interface"
  tags = {
    Name = var.deployment_tag
  }
  security_group_ids = [aws_security_group.vpc_interface_security_group.id]
  subnet_ids = values(aws_subnet.private_subnets)[*].id
  private_dns_enabled = true
}