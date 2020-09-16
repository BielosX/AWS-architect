output "cluster_security_group" {
  value = aws_security_group.cluster_security_group.id
}

output "mount_target_security_group" {
  value = aws_security_group.mount_target_sg.id
}