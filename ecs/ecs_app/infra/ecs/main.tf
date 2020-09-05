data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "ecs_app_log_group" {
  name = "ecs_app_log_group"
}

resource "aws_ecr_repository" "ecs_app_repository" {
  name = "ecs_app"
}

locals {
  container_name = "ecs_app"
}

resource "aws_ecs_task_definition" "ecs_app_task_definition" {
  depends_on = [aws_ecr_repository.ecs_app_repository]
  container_definitions = <<EOT
    [
      {
        "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecs_app:latest",
        "name": "${local.container_name}",
        "memory": 512,
        "command": ["--profile", "aws"],
        "portMappings": {
          "containerPort": 4567,
          "hostPort": 0
        },
        "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
            "awslogs-group": "${aws_cloudwatch_log_group.ecs_app_log_group.name}",
            "awslogs-region": "${data.aws_region.current.name}"
          }
        }
      }
    ]
  EOT
  family = "ecs_app"
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = var.cluster_name
}

resource "aws_ecs_service" "ecs_app_service" {
  name = "ecs_app_service"
  cluster = data.aws_ecs_cluster.ecs_cluster.arn
  scheduling_strategy = "REPLICA"
  launch_type = "EC2"
  desired_count = 2
  task_definition = aws_ecs_task_definition.ecs_app_task_definition.arn
  load_balancer {
    container_name = local.container_name
    container_port = 0
    target_group_arn = var.lb_target_group
  }
}
