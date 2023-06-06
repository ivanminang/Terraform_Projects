variable "vpc_cidr" {
  description = "cidr of our vpc"
  type        = string
}

variable "aws_region" {
  description = "the aws region to deploy the infrastructure in"
  type = string  
}

variable "my_count" {
  description = "the number of resources to deploy"
  type = string
}

variable "pub_subnets_cidr" {
  description = "cidr block of our public subnets"
  type = list(string) 
}

variable "priv_subnets_cidr" {
  description = "cidr block of our public subnets"
  type = list(string) 
}

variable "aws_availability_zones" {
  description = "The availability zones to deploy our subnets"
  type = list(string)
}

variable "instance_type" {
  description = "The instance type to use for the EC2 instance"
  type = string 
}

variable "public_key" {
  description = "public key of my key pair"
  type = string 
}

variable "key_name" {
  description = "Name of the key pair"
  type = string 
}