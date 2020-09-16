resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
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

data "aws_iam_policy_document" "logs_document" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "logs_policy" {
  policy = data.aws_iam_policy_document.logs_document.json
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_container_service_fo_ec2" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_s3_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_ssm_read_only_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_role_policy_attachment" "attach_efs_full_access_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
  role = aws_iam_role.ec2_cluster_role.id
}

resource "aws_iam_instance_profile" "ec2_cluster_profile" {
  role = aws_iam_role.ec2_cluster_role.name
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  current_region = data.aws_region.current.name
  cloud_watch_agent_link = "https://s3.${local.current_region}.amazonaws.com/amazoncloudwatch-agent-${local.current_region}/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_ssm_parameter" "cloudwatch_config" {
  name = "/cloudwatch/agent/config"
  type = "String"
  value = file("${path.module}/amazon-cloudwatch-agent.json")
}

resource "aws_launch_template" "cluster_ec2_launch_template" {
  depends_on = [aws_ecs_cluster.cluster]
  tags = {
    Name = var.deployment_tag
  }
  user_data = base64encode(
          <<-EOF
            #!/bin/bash -xe
            exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "ECS_CLUSTER=${aws_ecs_cluster.cluster.name}" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_TASK_IAM_ROLE=true" >> /etc/ecs/ecs.config
              echo "ECS_ENABLE_TASK_IAM_ROLE_NETWORK_HOST=true" >> /etc/ecs/ecs.config
              echo "AWS_DEFAULT_REGION=${data.aws_region.current.name}" >> /etc/ecs/ecs.config
              echo '["json-file","syslog","awslogs","none"]' >> /etc/ecs/ecs.config
              curl ${local.cloud_watch_agent_link} -o amazon-cloudwatch-agent.rpm
              rpm -U ./amazon-cloudwatch-agent.rpm
              yum install -y amazon-efs-utils
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c ssm:${aws_ssm_parameter.cloudwatch_config.name}
              mount -t efs -o tls,iam ${var.docker_volumes_fs_id} /var/lib/docker/volumes
          EOF
  )
  instance_type = "t2.micro"
  image_id = data.aws_ssm_parameter.recommended_ami.value
  vpc_security_group_ids = [var.cluster_security_group]
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