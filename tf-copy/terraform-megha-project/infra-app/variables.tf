# AWS Configuration

variable "aws_region" {
  description = "AWS Region"
  type        = string

}

variable "project_name" {
  description = "Project Name"
  type        = string

}

#variable "environment" {
#  description = "Environment Name"
# type        = string

#}
variable "vpc_cidr" {
  description = "CIDR Block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR Block for Public Subnet"
  type        = string
}
variable "availability_zone" {
  description = "Availability Zone"
  type        = string
}
variable "public_key_path" {
  description = "Path to the SSH Public Key"
  type        = string
}

variable "user_data_path" {
  description = "Path to user data script"
  type        = string
}

