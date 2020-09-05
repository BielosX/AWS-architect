data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "allow_ssm_parameters_access" {
  statement {
    actions = [
      "ssm:*"
    ]
    effect = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "logs:*"
    ]
    effect = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "ec2:*"
    ]
    effect = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "kms:*"
    ]
    effect = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_role" "codebuild_role" {
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
}

resource "aws_iam_role_policy" "allow_ssm_parameters_policy" {
  policy = data.aws_iam_policy_document.allow_ssm_parameters_access.json
  role = aws_iam_role.codebuild_role.id
}

resource "aws_security_group" "psql_security_group" {
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 5432
    protocol = "tcp"
    to_port = 5432
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 5432
    protocol = "tcp"
    to_port = 5432
  }
  vpc_id = var.vpc_id
}
resource "aws_security_group" "https_allow_security_group" {
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  vpc_id = var.vpc_id
}

resource "aws_codebuild_project" "ecs_app_init_db" {
  name = "ecs_app_init_db"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type = "LINUX_CONTAINER"
  }
  source {
    type = "NO_SOURCE"
    buildspec = file("${path.module}/psql_user_init.yml")
  }
  vpc_config {
    security_group_ids = [aws_security_group.psql_security_group.id, aws_security_group.https_allow_security_group.id]
    subnets = var.build_subnets
    vpc_id = var.vpc_id
  }
}

resource "aws_codebuild_project" "db_migrate" {
  name = "db_migrate"
  service_role = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    type = "LINUX_CONTAINER"
  }
  source {
    type = "GITHUB"
    location = "https://github.com/BielosX/AWS-architect.git"
    buildspec = file("${path.module}/db_migrate.yml")
  }
  source_version = "master"
  vpc_config {
    security_group_ids = [aws_security_group.psql_security_group.id, aws_security_group.https_allow_security_group.id]
    subnets = var.build_subnets
    vpc_id = var.vpc_id
  }
}