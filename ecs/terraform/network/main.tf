resource "aws_vpc" "cluster_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = toset(["10.0.1.0/24", "10.0.2.0/24"])
  vpc_id = aws_vpc.cluster_vpc.id
  tags = {
    Name = var.deployment_tag
  }
  cidr_block = each.value
  map_public_ip_on_launch = false
}
