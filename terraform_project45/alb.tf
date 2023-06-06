
resource "aws_lb_target_group" "alb_tg" {
  name       = "alb-tg"
  port       = var.port_number[0]
  protocol   = var.protocols[0]
  vpc_id     = aws_vpc.project4_vpc.id

  # stickiness {
  #   enabled = false
  #   type    = "lb_cookie"
  # }

  health_check {
    enabled             = true
    port                = var.port_number[0]
    interval            = 5
    protocol            = var.protocols[0]
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
  }
}

resource "aws_lb_listener" "alb_list" {
  load_balancer_arn = aws_lb.app_lb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
  }
}

resource "aws_lb" "app_lb" {
    
 
  #Conditional statement
  #If we have more than 2 ec2 instances, then create ALB
  #If we have > 2 instances , set count = 1. If not set count = 0

  name               = "app-lb"
  count = length(aws_instance.linux_server[*].id) > 2 ? 1:0
  internal           = false

  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # access_logs {
  #   bucket  = "my-logs"
  #   prefix  = "my-app-lb"
  #   enabled = true
  # }

  subnets = [
    aws_subnet.pub_subnet1.id,
    aws_subnet.pub_subnet2.id,
    aws_subnet.pub_subnet3.id
  ]
}

resource "aws_lb_target_group_attachment" "alb_tg_at" {
  count = var.my_count
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.linux_server[count.index].id
  port             = 80
  
}
