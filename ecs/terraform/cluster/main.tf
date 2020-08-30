resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
  tags = {
    Name = var.deployment_tag
  }
}

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

data "aws_ssm_parameter" "recommended_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_iam_policy_document" "ec2_cluster_role_assume" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "ec2_cluster_role" {
  assume_role_policy = data.aws_iam_policy_document.ec2_cluster_role_assume.json
}

data "aws_iam_policy_document" "create_log_group_document" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "create_log_group_policy" {
  policy = data.aws_iam_policy_document.create_log_group_document.json
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_container_service_fo_ec2" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_instance_profile" "ec2_cluster_profile" {
  role = aws_iam_role.ec2_cluster_role.name
}

data "aws_region" "current" {}

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
            echo "AWS_DEFAULT_REGION=${data.aws_region.current.name}" >> /etc/ecs/ecs.config
            echo '["json-file","syslog","awslogs","none"]' >> /etc/ecs/ecs.config
          EOF
  )
  instance_type = "t2.micro"
  image_id = data.aws_ssm_parameter.recommended_ami.value
  vpc_security_group_ids = [aws_security_group.cluster_security_group.id]
  key_name = var.key_pair
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_cluster_profile.name
  }
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