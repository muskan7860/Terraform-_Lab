module "s3" {

  source = "../modules/s3"

  project_name = var.project_name

  environment = "shared"

  bucket_name = var.bucket_name

}

module "dynamodb" {

  source = "../modules/dynamodb"

  project_name = var.project_name

  environment = "shared"

  table_name = var.table_name

}