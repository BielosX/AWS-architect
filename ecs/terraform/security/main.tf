resource "aws_security_group" "cluster_security_group" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_security_group" "mount_target_sg" {
  vpc_id = var.vpc_id
  ingress {
    security_groups = [aws_security_group.cluster_security_group.id]
    from_port = 2049
    protocol = "tcp"
    to_port = 2049
  }
  egress {
    security_groups = [aws_security_group.cluster_security_group.id]
    from_port = 2049
    protocol = "tcp"
    to_port = 2049
  }
}
