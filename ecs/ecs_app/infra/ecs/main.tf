data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "ecs_app_log_group" {
  name = "ecs_app_log_group"
}

resource "aws_ecr_repository" "ecs_app_repository" {
  name = "ecs_app"
}

resource "aws_ecs_task_definition" "ecs_app_task_definition" {
  depends_on = [aws_ecr_repository.ecs_app_repository]
  container_definitions = <<EOT
    [
      {
        "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/ecs_app:latest",
        "name": "ecs_app",
        "memory": 512,
        "command": ["--profile", "aws"],
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

resource "aws_ecs_service" "ecs_app_service" {
  name = "ecs_app_service"
  cluster = var.cluster_arn
  scheduling_strategy = "REPLICA"
  desired_count = 1
  launch_type = "EC2"
  task_definition = aws_ecs_task_definition.ecs_app_task_definition.arn
}