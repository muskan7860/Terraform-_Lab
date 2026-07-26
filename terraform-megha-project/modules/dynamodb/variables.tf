variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
}