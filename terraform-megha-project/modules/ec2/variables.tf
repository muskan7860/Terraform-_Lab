#Project Configuration
variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "environment" {
  description = "Environment"
  type        = string

}
# EC2 Configuration

variable "ami_id" {
  description = "AMI ID"
  type        = string
}
variable "instance_type" {
  description = "Ec2 Instance Type"
  type        = string

}
variable "instance_count" {
  description = "Number of EC2 Instances"
  type        = number
}
# Networking Configuration
variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string

}
variable "key_name" {
  type = string
}

#SSH
variable "key_name" {
  description = "AWS Key Pair Name"
  type        = string
}
#Storage

variable "root_volume_size" {
  description = "Root Volume Size (GB)"
  type        = number
}

# User Data
variable "user_data_path" {
  description = "Path to User Data Script"
  type        = string
}

#Associate public ip
variable "associate_public_ip" {
  description = "Assign Public IP to EC2"
  type        = bool
}
 