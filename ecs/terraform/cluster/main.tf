resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_security_group" "cluster_security_group" {
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = ["tcp", "udp"]
    content {
      from_port = 0
      to_port = 65535
      cidr_blocks = ["0.0.0.0/0"]
      protocol = ingress.value
    }
  }
  dynamic "egress" {
    for_each = ["tcp", "udp"]
    content {
      from_port = 0
      to_port = 65535
      cidr_blocks = ["0.0.0.0/0"]
      protocol = egress.value
    }
  }

  tags = {
    Name = var.deployment_tag
  }
}

resource "aws_launch_template" "cluster_ec2_launch_template" {
  depends_on = [aws_ecs_cluster.cluster]
  tags = {
    Name = var.deployment_tag
  }
  user_data = base64encode(
          <<EOF
            #!/bin/bash -xe
            echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
            echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
            echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
            echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config
          EOF
  )
  instance_type = "t2.micro"
  image_id = "ami-01f62a207c1d180d2"
  vpc_security_group_ids = [aws_security_group.cluster_security_group.id]
  key_name = var.key_pair
}

resource "aws_autoscaling_group" "cluster_auto_scaling_group" {
  max_size = var.max_instances
  min_size = var.min_instances
  launch_template {
    version = "$Latest"
    id = aws_launch_template.cluster_ec2_launch_template.id
  }
  tag {
    key = "Name"
    propagate_at_launch = true
    value = var.deployment_tag
  }
  vpc_zone_identifier = var.subnets
}