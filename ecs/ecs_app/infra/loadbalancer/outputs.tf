output "target_group_arn" {
  value = aws_lb_listener.ecs_app_listener.default_action[0].target_group_arn
}