# Root Module
# This file orchestrates all resuable modules.action
# As we build each module, it will be called from here.
module "vpc" {
  source              = "../modules/vpc"
  project_name        = var.project_name
  environment         = terraform.workspace
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = local.selected_azs
  # Left side variable expected by vpc module and Right side variable from Root Module.

}


module "security_group" {
  source         = "../modules/security-group"
  project_name   = var.project_name
  environment    = terraform.workspace
  ssh_allowed_ip = "0.0.0.0/0"
  vpc_id         = module.vpc.vpc_id
}

#module "keypair" {
 # source          = "../modules/keypair"
  #project_name    = var.project_name
  #e#public_key_path = var.public_key_path
#}

module "ec2" {

  source = "../modules/ec2"

  project_name = var.project_name
  environment  = terraform.workspace

  ami_id = data.aws_ami.ubuntu.id

  subnet_id = module.vpc.public_subnet_ids[0]

  security_group_id = module.security_group.security_group_id

  key_name = var.key_name

  instance_type = local.instance_type[terraform.workspace]

  instance_count = local.instance_count[terraform.workspace]

  root_volume_size    = local.root_volume_size[terraform.workspace]
  user_data_path      = var.user_data_path
  associate_public_ip = local.associate_public_ip[terraform.workspace]

}

