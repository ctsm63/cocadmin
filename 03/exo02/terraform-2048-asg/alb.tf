# Application Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.my_subnets.ids
  enable_deletion_protection = false
}

# Target Group qui vise le port 5000 en HTTP
resource "aws_lb_target_group" "app_lb_target_group" {
  name        = "app-lb-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.my_vpc.id
  target_type = "instance"
}

# Listener sur le port 80 en HTTP
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_lb_target_group.arn
  }
}

