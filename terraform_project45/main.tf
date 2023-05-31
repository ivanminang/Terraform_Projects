
# Define the vpc with the cidr
resource "aws_vpc" "project4_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  tags = {
    Name = "project4_vpc"
  }
}
# public subnet 1
resource "aws_subnet" "pub_subnet1" {
  vpc_id            = aws_vpc.project4_vpc.id
  cidr_block        = var.subnets_cidr["public_subnet1_cidr"]
  availability_zone = var.aws_availability_zones[0]
  tags = {
    Name = "pub_subnet1"
  }
}
#public subnet2
resource "aws_subnet" "pub_subnet2" {
  vpc_id            = aws_vpc.project4_vpc.id
  cidr_block        = var.subnets_cidr["public_subnet2_cidr"]
  availability_zone = var.aws_availability_zones[1]
  tags = {
    Name = "pub_subnet2"
  }
}
#public subnet 3
resource "aws_subnet" "pub_subnet3" {
  vpc_id            = aws_vpc.project4_vpc.id
  cidr_block        = var.subnets_cidr["public_subnet3_cidr"]
  availability_zone = var.aws_availability_zones[2]
  tags = {
    Name = "pub_subnet3"
  }
}

#private subnet1
resource "aws_subnet" "priv_subnet1" {
  vpc_id            = aws_vpc.project4_vpc.id
  cidr_block        = var.subnets_cidr["private_subnet1_cidr"]
  availability_zone = var.aws_availability_zones[0]
  tags = {
    Name = "priv_subnet1"
  }
}
#private subnet2
resource "aws_subnet" "priv_subnet2" {
  vpc_id            = aws_vpc.project4_vpc.id
  cidr_block        = var.subnets_cidr["private_subnet2_cidr"]
  availability_zone = var.aws_availability_zones[1]
  tags = {
    Name = "priv_subnet2"
  }
}
#private subnet3
resource "aws_subnet" "priv_subnet3" {
  vpc_id            = aws_vpc.project4_vpc.id
  cidr_block        = var.subnets_cidr["private_subnet3_cidr"]
  availability_zone = var.aws_availability_zones[2]
  tags = {
    Name = "priv_subnet3"
  }
}


# Internet gateway
resource "aws_internet_gateway" "project4_igw" {
  vpc_id = aws_vpc.project4_vpc.id
  tags = {
    Name = "project4_igw"
  }
}
# A Route table for the publics subnets
resource "aws_route_table" "project4_pub_rt" {
  vpc_id = aws_vpc.project4_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project4_igw.id
  }
  

  tags = {
    Name = "project4_pub_rt"
  }
}

# The EC2 instance
resource "aws_instance" "linux_server" {
  count = var.my_count
  subnet_id = element(local.subnets, count.index)
  instance_type = var.instance_type["us-west-2a"]
  ami = data.aws_ami.linux_ami.id 
  vpc_security_group_ids = [ aws_security_group.project4_sg.id ]
  key_name = aws_key_pair.project4_keypair.id
  associate_public_ip_address = "true"

  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  sudo yum install -y httpd.x86_64
  sudo systemctl start httpd.service
  sudo systemctl enable httpd.service
  echo "WELCOME TO TERRAFORM CLASS
   You successfully access Joseph Mbatchou web page launched via Terraform code.
    Welcome here and we hope you will enjoy coding with Terraform!" > /var/www/html/index.html
  EOF

  tags = {
    Name = "linux_server-${var.aws_region}-${count.index+1}"
  }

}

resource "aws_key_pair" "project4_keypair" {
  key_name = var.key_pair_name
  public_key = var.public_key
  
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

# # Declare the data source for AZ
# data "aws_availability_zones" "az" {
#   state = "available"
# }

locals {
  subnets =  [ aws_subnet.pub_subnet1.id, aws_subnet.pub_subnet2.id, aws_subnet.pub_subnet3.id ]
}

# locals {
#   # Group all common tags
#   common_tags = {
#     Name = "Project4-${var.aws_region}"
#     Company = "Cloudspace"
#     Project = var.project
#     Region = var.aws_region
#     Department = var.department
#     Contact_email = var.contact_email
#     Billing_code = "${var.department}-${var.contact_email}"
#   }
# }








 

