# EC2 Instance

resource "aws_instance" "ec2" {
  # Number of EC2 instances to create
  count = var.instance_count

  #EC2 Confihuration
  ami           = var.ami_id
  instance_type = var.instance_type

  #Networking

  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]

  associate_public_ip_address = var.associate_public_ip

  # SSH key
   key_name = var.key_name

  # Root EBS olume

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  # Bootstrap Script
  user_data = file(var.user_data_path)

  #Tags
  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-${count.index + 1}"
  }




}