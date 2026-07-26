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

variable "public_subnet_cidrs" {

  description = "Public subnet CIDRs"

  type = list(string)

}

variable "availability_zones" {

  description = "List of Availability Zones"

  type = list(string)

}
