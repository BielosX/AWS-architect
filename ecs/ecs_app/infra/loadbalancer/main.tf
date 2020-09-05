resource "aws_security_group" "lb_security_group" {
  vpc_id = var.vpc_id
  ingress {
    from_port = 0
    protocol = "tcp"
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol = "tcp"
    to_port = 65535
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "application_lb" {
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.lb_security_group.id]
  subnets = var.public_subnets
}

resource "aws_lb_target_group" "app_lb_target_group" {
  port = 4567
  target_type = "instance"
  protocol = "HTTP"
  vpc_id = var.vpc_id
}

resource "aws_lb_listener" "ecs_app_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port = 80
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app_lb_target_group.arn
  }
}