output "first_subnet_id" {
  value = aws_subnet.private_subnet["10.0.0.0/25"].id
}

output "second_subnet_id" {
  value = aws_subnet.private_subnet["10.0.0.128/25"].id
}

output "vpc_id" {
  value = aws_vpc.lambda_vpc.id
}
