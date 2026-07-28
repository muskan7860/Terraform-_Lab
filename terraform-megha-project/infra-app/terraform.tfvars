# AWS Configuration

aws_region   = "ap-south-1"
project_name = "terraform-megha-project"


vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = [

  "10.0.1.0/24",

  "10.0.2.0/24"

]



key_name       = "terraform-megha-project-dev-key"
user_data_path = "../scripts/user-data.sh"


