
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
