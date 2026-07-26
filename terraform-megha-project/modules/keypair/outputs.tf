output "key_name" {
  description = "AWS Key Pair Name"
  value       = aws_key_pair.terraform_key.key_name
}