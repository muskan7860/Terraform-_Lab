#EC2 outputs

output "instance_ids" {
  description = "EC@ Instance ID's"
  value       = aws_instance.ec2[*].id

}

output "public_ips" {
  description = "Public IP Addresses"
  value       = aws_instance.ec2[*].public_ip

}

output "private_ips" {
  description = "Prvate IP Addresses"
  value       = aws_instance.ec2[*].private_ip
}
