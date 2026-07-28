####################################
# VPC Outputs
####################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnet_ids
}

####################################
# Security Group Outputs
####################################

output "security_group_id" {
  description = "Security Group ID"
  value       = module.security_group.security_group_id
}

####################################
# Key Pair Outputs
output "key_name" {
  value = var.key_name
}
####################################
# AMI Outputs
####################################

output "ubuntu_ami" {
  description = "Latest Ubuntu 24.04 LTS AMI ID"
  value       = data.aws_ami.ubuntu.id
}

####################################
# EC2 Outputs
####################################

output "instance_ids" {
  description = "EC2 Instance IDs"
  value       = module.ec2.instance_ids
}

output "public_ips" {
  description = "EC2 Public IP Addresses"
  value       = module.ec2.public_ips
}

output "private_ips" {
  description = "EC2 Private IP Addresses"
  value       = module.ec2.private_ips
}