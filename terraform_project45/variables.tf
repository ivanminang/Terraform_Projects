
# Variables Block (configure all the variables)
# variable "key_pair_name" {
#   description = " the key name for my keypair"
#   type = string  
# }

# variable "public_key" {
#   description = "The public key for my keypair"
#   type = string
  
# }

variable "key_pair_name" {
  description = "The name of my keypair"
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

variable "alb_sg_ingress_rules" {
  description = "ingress security group rules for alb"
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))  
}

variable "port_number" {
  description = "The ports of the security groups"
  type = list(string)
  
}

variable "protocol_type" {
  description = "The protocol type, mostly tcp"
  type = string
  
}

variable "protocols" {
  description = "The protocols "
  type = list(string)
  
}


variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  type = map(string)
  
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

variable "aws_availability_zones" {
  description = "The availability zones to deploy our subnets"
  type = list(string)
  
}

variable "project" {
  description = "The name of the curent project"
  type = string
}

variable "my_count" {
  description = "The number of resources"
  type = number
  
}

variable "department" {
  description = "The department in charge of the project"
  type = string
}

variable "contact_email" {
  description = "The company email adress"
  type = string
}
