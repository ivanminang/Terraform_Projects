# ************************** VPC Section*********************************************************
# VPC creation
resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "my_vpc"
  }
}
# Internet Gateway Creation
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw"
  }
}

# # ********************* Subnets Section**************************************************
# Public Subnets Creation
resource "aws_subnet" "pub_subnets" {   
  count             = var.my_count  
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.pub_subnets_cidr[count.index]
  availability_zone = var.aws_availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "pub_subnet-${count.index+1}"
  }
}
# # Private Subnets Creation
resource "aws_subnet" "priv_subnets" {   
  count             = var.my_count  
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.priv_subnets_cidr[count.index]
  availability_zone = var.aws_availability_zones[count.index]
  # map_public_ip_on_launch = true
  tags = {
    Name = "priv_subnet-${count.index+1}"
  }
}
# Nacl Creation and Association to public Subnets
resource "aws_network_acl" "my_nacl" {
  vpc_id = aws_vpc.my_vpc.id
  subnet_ids = aws_subnet.pub_subnets[*].id

  egress {
    rule_no = 100
    protocol    = "all"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }
  ingress {
    rule_no = 100
    protocol    = "all"
    action      = "allow"
    cidr_block  = "0.0.0.0/0"
    from_port   = 0
    to_port     = 0
  }
  tags = {
    "Name" = "my_nacl"
  }
}

# Public Route table Creation for the public subnets
resource "aws_route_table" "my_pub_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
  tags = {
    Name = "my_pub_rt"
  }
}
# Public Route table Association with the public subnets
resource "aws_route_table_association" "pub_rt_ass" {
  count = var.my_count
  subnet_id      = "${element(aws_subnet.pub_subnets.*.id, count.index)}"
  route_table_id = aws_route_table.my_pub_rt.id
}

#*******************************  Security Groups Section**************************
# Web Server Security Group Creation
resource "aws_security_group" "myweb_sg" {
  description = "security group for my web servers open to alb sg"
  name        = "myweb_sg"
  vpc_id      = aws_vpc.my_vpc.id
  lifecycle {
    create_before_destroy = true
  }
  timeouts {
    delete = "2m"
  }

  ingress {
    description = "ssh access from the vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description                = "receives traffic from alb"
    from_port                  = 80
    to_port                    = 80
    protocol                   = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
  }

  ingress {
    description                = "receives traffic from elb"
    from_port                  = 443
    to_port                    = 443
    protocol                   = "tcp"
    security_groups = [aws_security_group.alb_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myweb_sg"
  }
}

# Load Balancer Security Group Creation
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "alb security group"
  vpc_id      = aws_vpc.my_vpc.id
  lifecycle {
    create_before_destroy = true
  }
  timeouts {
    delete = "2m"
  }
    

  ingress {
    description                = "receives HTTP traffic from internet"
    from_port                  = 80
    to_port                    = 80
    protocol                   = "tcp"
    cidr_blocks                = ["0.0.0.0/0"]
  }

  ingress {
    description                = "receives HTTPS traffic from internet"
    from_port                  = 443
    to_port                    = 443
    protocol                   = "tcp"
    cidr_blocks                = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb_sg"
  }
}

#*****************************************Autoscalimg Section***************************************
# resource "aws_launch_configuration" "my_config" {
#   name          = "my_config"
#   # name_prefix   = "web_server"
#   image_id      = data.aws_ami.linux_ami.id
#   instance_type = var.instance_type
#   key_name      = var.key_name
#   security_groups = [ aws_security_group.myweb_sg.id ]
#   associate_public_ip_address = true
#   user_data = <<-EOF
#     #!/bin/bash
#     yum update -y
#     yum install -y httpd
#     systemctl enable httpd
#     systemctl start httpd
#     echo "Hello from Terraform! Welcome to Ivan Minang Website" > /var/www/html/index.html
#   EOF

#   lifecycle {
#     create_before_destroy = true
#   }
# }

##  Launch template Creation
resource "aws_launch_template" "mylaunchtempl" {
  name = "mylaunchtempl"
  description = "My Launch Template for Auto Scaling"
  image_id = data.aws_ami.linux_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name
  vpc_security_group_ids = [ aws_security_group.myweb_sg.id ]
  # associate_public_ip_address = true
  user_data = filebase64("${path.module}/userdata.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
        Name = "mylaunchtemplate"
    }
  }
  lifecycle {
    create_before_destroy = true
  } 
}
resource "aws_autoscaling_group" "my_asg" {
  name                 = "my_asg"
  launch_template {
    id      = aws_launch_template.mylaunchtempl.id
    version = "$Latest"
  }
  min_size             = 2
  max_size             = 5
  desired_capacity     = 3
  vpc_zone_identifier  = local.subnets 
  # vpc_zone_identifier  = aws_subnet.pub_subnets.*.id #(This syntax also works for vpc zone identifier)
  target_group_arns = [aws_lb_target_group.myalb_tg.arn] # ASG attachment With ALB Target Group
  tag {
    key                 = "Name"
    value               = "web_server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# key pair Creation 
resource "aws_key_pair" "my_keypair" {
  key_name   = "my_keypair"
  public_key = var.public_key
}


# **********************************Load Balancer Section**************************
# Target Group Creation
resource "aws_lb_target_group" "myalb_tg" {
  name       = "myalb-tg"
  port       = 80
  protocol   =  "HTTP"   #"TCP"
  vpc_id     = aws_vpc.my_vpc.id
  # depends_on = [aws_instance.linux_server]

  health_check {
    # enabled             = true
    port                = 80
    # interval            = 5
    protocol            = "HTTP"
    path                = "/"
    # matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }
}
# Load Balancer Creation
resource "aws_lb" "app_lb" {

  name               = "app-lb"
  # count = length(aws_autoscaling_group.my_asg[*].id) > 2 ? 1:0
  internal           = false

  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets            = [for subnet in aws_subnet.pub_subnets : subnet.id]
}

# ALB Listener Creation
resource "aws_lb_listener" "myalb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  # load_balancer_arn = aws_lb.app_lb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb_tg.arn
  }
}



# # Auto scalling attachment with ALB target group
# resource "aws_autoscaling_attachment" "alb_tg_attach" {
#   autoscaling_group_name = aws_autoscaling_group.my_asg.id
#   lb_target_group_arn    = aws_lb_target_group.myalb_tg.arn
# }

#************************************Locals and Data Section**********************************************
# Local for public subnets id
locals {
  subnets =  [ aws_subnet.pub_subnets[0].id, aws_subnet.pub_subnets[1].id, aws_subnet.pub_subnets[2].id ]
}

# data source block (configure the data sources)
data "aws_ami" "linux_ami" {
  most_recent = true
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm*" ]
  }
  owners = [ "amazon" ]  
}





  

