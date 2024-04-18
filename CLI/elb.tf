resource "aws_lb" "test_alb" {
  name               = "test-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "test_elb_listener_http" {
  load_balancer_arn = aws_lb.test_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.test_target_group.arn
    type             = "forward"
  }
}

#resource "aws_lb_listener" "test_elb_listener_https" {
#  load_balancer_arn = aws_lb.test_alb.arn
#  port              = 443
#  protocol          = "HTTPS"
#
#  default_action {
#    target_group_arn = aws_lb_target_group.test_target_group.arn
#    type             = "forward"
#  }
#}
resource "aws_lb_target_group" "test_target_group" {
  name_prefix = "app-"
  vpc_id      = aws_vpc.test_vpc.id
  protocol    = "HTTP"
  port        = 80
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = 80
    matcher             = 200
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

output "alb_url" {
  value = aws_lb.test_alb.dns_name
}