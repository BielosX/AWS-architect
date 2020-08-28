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

data "aws_region" "current" {}

data "aws_iam_policy_document" "ecr_s3_permission" {
  statement {
    actions = ["s3:GetObject"]
    effect = "Allow"
    resources = ["arn:aws:s3:::prod-${data.aws_region.current.name}-starport-layer-bucket/*"]
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