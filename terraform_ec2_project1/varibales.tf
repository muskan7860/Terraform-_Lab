####################################
# AWS Configuration
####################################

variable "aws_region" {
  description = "AWS Region where resources will be created"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project Name"
  type        = string
  default     = "terraform-ec2"
}

variable "environment" {
  description = "Environment Name"
  type        = string
  default     = "dev"
}

####################################
# Network Configuration
####################################

variable "vpc_cidr" {
  description = "CIDR Block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR Block for Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone"
  type        = string
  default     = "ap-south-1a"
}

####################################
# EC2 Configuration
####################################

variable "ami_id" {
  description = "Enter the AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Enter EC2 Instance Type (Example: t3.micro)"
  type        = string
}

variable "instance_count" {
  description = "Number of EC2 Instances"
  type        = number
  default     = 1
}

####################################
# Security Group
####################################

variable "ssh_allowed_ip" {
  description = "CIDR allowed to SSH into EC2"
  type        = string
  default     = "0.0.0.0/0"
}
variable "root_volume_size" {
  description = "Root EBS Volume Size in GB"
  type        = number
  default     = 20
}