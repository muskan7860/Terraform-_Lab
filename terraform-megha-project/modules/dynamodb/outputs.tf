output "table_name" {

  description = "Terraform Lock Table"

  value = aws_dynamodb_table.terraform_lock.name

}