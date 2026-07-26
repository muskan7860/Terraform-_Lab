# AWS Configuration

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "ap-south-1"

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

variable "public_subnet_cidrs" {

  description = "Public subnet CIDRs"

  type = list(string)

}
variable "availability_zone_count" {

  description = "Number of Availability Zones"

  type = number

  default = 2

}
variable "public_key_path" {
  description = "Path to the SSH Public Key"
  type        = string
}

variable "user_data_path" {
  description = "Path to user data script"
  type        = string
}

