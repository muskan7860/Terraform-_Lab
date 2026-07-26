# VPC Outputs

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR Block for VPC"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {

  description = "Public Subnet IDs"

  value = aws_subnet.public[*].id

}