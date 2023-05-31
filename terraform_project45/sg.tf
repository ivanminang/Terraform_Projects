
resource "aws_security_group" "project4_sg" {
  name        = "project4_sg"
  description = "project4 security group"
  vpc_id      = aws_vpc.project4_vpc.id

#   depends_on  = [aws_security_group.alb_sg]

  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "project4_sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "alb security group"
  vpc_id      = aws_vpc.project4_vpc.id

  dynamic "ingress" {
    for_each = var.alb_sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
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

resource "aws_security_group_rule" "ingress_alb_http_traffic" {
  type                     = "ingress"
  from_port                = var.port_number[0]
  to_port                  = var.port_number[0]
  protocol                 = var.protocol_type
  security_group_id        = aws_security_group.project4_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_alb_https_traffic" {
  type                     = "ingress"
  from_port                = var.port_number[1]
  to_port                  = var.port_number[1]
  protocol                 = var.protocol_type
  security_group_id        = aws_security_group.project4_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "egress_alb_http_traffic" {
  type                     = "egress"
  from_port                = var.port_number[0]
  to_port                  = var.port_number[0]
  protocol                 = var.protocol_type
  security_group_id        = aws_security_group.project4_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "egress_alb_https_traffic" {
  type                     = "egress"
  from_port                = var.port_number[1]
  to_port                  = var.port_number[1]
  protocol                 = var.protocol_type
  security_group_id        = aws_security_group.project4_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}











# resource "aws_security_group_rule" "egress_alb_health_check" {
#   type                     = "egress"
#   from_port                = 80
#   to_port                  = 80
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.project4_sg.id
#   source_security_group_id = aws_security_group.alb_sg.id
# }
