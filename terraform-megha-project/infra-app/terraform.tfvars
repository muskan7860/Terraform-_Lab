# AWS Configuration

aws_region   = "ap-south-1"
project_name = "terraform-megha-project"


vpc_cidr = "10.0.0.0/16"
public_subnet_cidrs = [

  "10.0.1.0/24",

  "10.0.2.0/24"

]



public_key_path = "../ssh-keys/terrra-key-ec2.pub"
user_data_path  = "../scripts/user-data.sh"


