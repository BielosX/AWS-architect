provider "aws" {
  region = var.region
}

resource "aws_vpc" "lambda_vpc" {
  cidr_block = "10.0.0.0/24"
}

resource "aws_route_table" "route_table" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
}

resource "aws_subnet" "private_subnet" {
  for_each = {
    "10.0.0.0/25" = "us-east-1b"
    "10.0.0.128/25" = "us-east-1a"
  }
  cidr_block = each.key
  availability_zone = each.value
  vpc_id = "${aws_vpc.lambda_vpc.id}"
}

resource "aws_route_table_association" "first_subnet" {
  subnet_id = aws_subnet.private_subnet["10.0.0.0/25"].id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_route_table_association" "second_subnet" {
  subnet_id = aws_subnet.private_subnet["10.0.0.128/25"].id
  route_table_id = aws_route_table.route_table.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id = "${aws_vpc.lambda_vpc.id}"
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = ["${aws_route_table.route_table.id}"]
}
