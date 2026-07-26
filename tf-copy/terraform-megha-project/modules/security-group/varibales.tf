variable "project_name" {
  description = "Project Name"
}

variable "environment" {
  description = "Environment"
  type        = string
}

variable "ssh_allowed_ip" {
  description = "CIDR allowed for ssh"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
