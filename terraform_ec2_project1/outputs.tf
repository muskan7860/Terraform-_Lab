####################################
# EC2 Outputs
####################################

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.ec2[*].id
}

output "public_ip" {
  description = "Public IP Address"
  value       = aws_instance.ec2[*].public_ip
}

output "public_dns" {
  description = "Public DNS"
  value       = aws_instance.ec2[*].public_dns
}

####################################
# Network Outputs
####################################

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.ec2_sg.id
}