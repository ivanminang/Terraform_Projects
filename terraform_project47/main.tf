# ************************** VPC*********************************************************
resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "my_vpc"
  }
}

# # *********************public subnets**************************************************
resource "aws_subnet" "pub_subnets" {   
  count             = var.my_count  
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.pub_subnets_cidr[count.index]
  availability_zone = var.aws_availability_zones[count.index]
  tags = {
    Name = "pub_subnet-${count.index+1}"
  }
}
#************************private Subnets**************************************************
resource "aws_subnet" "priv_subnets" {   
  count             = var.my_count  
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.priv_subnets_cidr[count.index]
  availability_zone = var.aws_availability_zones[count.index]
  tags = {
    Name = "priv_subnet-${count.index+1}"
  }
}

resource "aws_launch_configuration" "my_config" {
  name          = "my_config"
  # name_prefix   = "web_server"
  image_id      = data.aws_ami.linux_ami.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [ aws_security_group.myweb_sg.id ]
  associate_public_ip_address = true
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "Hello from Terraform! Welcome to Ivan Minang Website" > /var/www/html/index.html
  EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "my_asg" {
  name                 = "my_asg"
  launch_configuration = aws_launch_configuration.my_config.name
  min_size             = 2
  max_size             = 5
  desired_capacity     = 3
  # vpc_zone_identifier  = element(local.subnets, count.index)
  vpc_zone_identifier  = local.subnets 
  tag {
    key                 = "Name"
    value               = "web_server"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

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
#*******************************key pair****************************************
resource "aws_key_pair" "my_keypair" {
  key_name   = "my_keypair"
  public_key = var.public_key
}
#******************************* Web server Security Group**************************
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
    security_groups = [aws_security_group.alb_sg.id] # insert the sg of the alb and remove the cidr
  }

  ingress {
    description                = "receives traffic from elb"
    from_port                  = 443
    to_port                    = 443
    protocol                   = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # insert the sg of the alb and remove the cidr
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

resource "aws_network_acl_association" "nacl_ass1" {
  network_acl_id = aws_network_acl.my_nacl.id
  subnet_id      = aws_subnet.pub_subnets[0].id
}

resource "aws_network_acl_association" "nacl_ass2" {
  network_acl_id = aws_network_acl.my_nacl.id
  subnet_id      = aws_subnet.pub_subnets[1].id
}

resource "aws_network_acl_association" "nacl_ass3" {
  network_acl_id = aws_network_acl.my_nacl.id
  subnet_id      = aws_subnet.pub_subnets[2].id
}


resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "my_igw"
  }
}
# A Route table for the publics subnets
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

resource "aws_route_table_association" "rt_ass1" {
  subnet_id      = aws_subnet.pub_subnets[0].id
  route_table_id = aws_route_table.my_pub_rt.id
}

resource "aws_route_table_association" "rt_ass2" {
  subnet_id      = aws_subnet.pub_subnets[1].id
  route_table_id = aws_route_table.my_pub_rt.id
}

resource "aws_route_table_association" "rt_ass3" {
  subnet_id      = aws_subnet.pub_subnets[2].id
  route_table_id = aws_route_table.my_pub_rt.id
}

resource "aws_lb_target_group" "myalb_tg" {
  name       = "myalb-tg"
  port       = 80
  protocol   = "HTTP"
  vpc_id     = aws_vpc.my_vpc.id
  # depends_on = [aws_instance.linux_server]

  health_check {
    enabled             = true
    port                = 80
    interval            = 5
    protocol            = "HTTP"
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  # load_balancer_arn = aws_lb.app_lb[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.myalb_tg.arn
  }
}

resource "aws_lb" "app_lb" {

  name               = "app-lb"
  # count = length(aws_autoscaling_group.my_asg[*].id) > 2 ? 1:0
  internal           = false

  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets            = [for subnet in aws_subnet.pub_subnets : subnet.id]
}

# Auto scalling attachment with ALB target group
resource "aws_autoscaling_attachment" "alb_tg_attach" {
  autoscaling_group_name = aws_autoscaling_group.my_asg.id
  lb_target_group_arn    = aws_lb_target_group.myalb_tg.arn
}




  

