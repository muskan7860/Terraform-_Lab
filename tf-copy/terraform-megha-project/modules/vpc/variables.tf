# VPC variables

variable "project_name" {
  description = "Project_name"
  type        = string
}
variable "environment" {
  description = "Environment Name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR Block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "Public Subnet CIDR Block"
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone"
  type        = string
}
