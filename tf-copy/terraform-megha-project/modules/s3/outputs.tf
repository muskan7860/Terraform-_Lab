output "bucket_name" {

  description = "Terraform State Bucket"

  value = aws_s3_bucket.terraform_state.bucket

}