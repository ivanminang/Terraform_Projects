
resource "aws_network_acl" "my_nacl" {
  vpc_id = aws_vpc.project4_vpc.id
  subnet_ids = local.subnets

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
  subnet_id      = aws_subnet.pub_subnet1.id
}

resource "aws_network_acl_association" "nacl_ass2" {
  network_acl_id = aws_network_acl.my_nacl.id
  subnet_id      = aws_subnet.pub_subnet2.id
}

resource "aws_network_acl_association" "nacl_ass3" {
  network_acl_id = aws_network_acl.my_nacl.id
  subnet_id      = aws_subnet.pub_subnet3.id
}