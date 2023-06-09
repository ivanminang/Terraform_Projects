
# Terraform Block (Define the required provider, his source and the provider version)
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
# Provider Block (Define the aws Provider and the region)
provider "aws" {
  region = var.aws_region
}
# Resources Block (configure all the resources)

# Define the vpc with the cidr
resource "aws_vpc" "project1_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  tags = {
    Name = "project1_vpc"
  }
}
# public subnet 1
resource "aws_subnet" "project1_pub_subnet1" {
  vpc_id            = aws_vpc.project1_vpc.id
  cidr_block        = var.subnets_cidr["public_subnet1_cidr"]
  availability_zone = data.aws_availability_zones.az.names[0]
  tags = {
    Name = "project1_pub_subnet1"
  }
}
#public subnet2
resource "aws_subnet" "project1_pub_subnet2" {
  vpc_id            = aws_vpc.project1_vpc.id
  cidr_block        = var.subnets_cidr["public_subnet2_cidr"]
  availability_zone = data.aws_availability_zones.az.names[1]
  tags = {
    Name = "project1_pub_subnet2"
  }
}
#private subnet1
resource "aws_subnet" "project1_priv_subnet1" {
  vpc_id            = aws_vpc.project1_vpc.id
  cidr_block        = var.subnets_cidr["private_subnet1_cidr"]
  availability_zone = data.aws_availability_zones.az.names[0]
  tags = {
    Name = "project1_priv_subnet1"
  }
}
#private subnet2
resource "aws_subnet" "project1_priv_subnet2" {
  vpc_id            = aws_vpc.project1_vpc.id
  cidr_block        = var.subnets_cidr["private_subnet2_cidr"]
  availability_zone = data.aws_availability_zones.az.names[1]
  tags = {
    Name = "project1_priv_subnet2"
  }
}
# Internet gateway
resource "aws_internet_gateway" "project1_igw" {
  vpc_id = aws_vpc.project1_vpc.id
  tags = {
    Name = "project1_igw"
  }
}
# A Route table for the publics subnets
resource "aws_route_table" "project1_pub_rt" {
  vpc_id = aws_vpc.project1_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project1_igw.id
  }
  

  tags = {
    Name = "project1_pub_rt"
  }
}

# The EC2 instance
resource "aws_instance" "project1_instance" {
  subnet_id = aws_subnet.project1_pub_subnet1.id
  instance_type = var.instance_type[1]
  ami = data.aws_ami.linux_ami.id 
  vpc_security_group_ids = [ aws_security_group.project1_sg.id ]
  key_name = aws_key_pair.project1_keypair.id
  associate_public_ip_address = "true"
  tags = {
    Name = "project1_instance"
  }

  user_data = <<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd.x86_64
  systemctl start httpd.service
  systemctl enable httpd.service
  echo "WELCOME TO TERRAFORM CLASS
   You successfully access Joseph Mbatchou web page launched via Terraform code.
    Welcome here and we hope you will enjoy coding with Terraform!" > /var/www/html/index.html
  EOF
}

resource "aws_key_pair" "project1_keypair" {
  key_name = var.key_pair_name
  public_key = var.public_key
  
}

resource "aws_network_acl" "my_nacl" {
  vpc_id = aws_vpc.project1_vpc.id
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

resource "aws_security_group" "project1_sg" {
  name        = "project1_sg"
  description = "project1 security group"
  vpc_id      = aws_vpc.project1_vpc.id

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
    Name = "project1_sg"
  }
}


# Variables Block (configure all the variables)
variable "key_pair_name" {
  description = " the key name for my keypair"
  type = string  
}

variable "public_key" {
  description = "The public key for my keypair"
  type = string
  
}

variable "sg_ingress_rules" {
  description = "ingress security group rules"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))  
}
variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  type = list(string) 
  
}
  
variable "vpc_cidr" {
  description = "cidr of our vpc"
  type        = string
}

variable "subnets_cidr" {
  description = "cidr block of our subnets"
  type = map(string)
    
}

variable "aws_region" {
  description = "the aws region to deploy the infrastructure in"
  type = string  
}


# Declare the data source for ami
data "aws_ami" "linux_ami" {
  most_recent = true
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm*" ]
  }
  owners = [ "amazon" ]  

}

# Declare the data source for AZ
data "aws_availability_zones" "az" {
  state = "available"
}

locals {
  subnets =  [ aws_subnet.project1_pub_subnet1.id, aws_subnet.project1_pub_subnet2.id ]
}






 

