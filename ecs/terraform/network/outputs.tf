output "vpc_id" {
  value = aws_vpc.cluster_vpc.id
}

output "private_subnets" {
  value = values(aws_subnet.private_subnets)[*].id
}

output "public_subnets" {
  value = values(aws_subnet.public_subnets)[*].id
}