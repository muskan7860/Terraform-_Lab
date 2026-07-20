resource "aws_instance" "ec2" {

  count = var.instance_count

  ami           = var.ami_id
  instance_type = var.instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  key_name = aws_key_pair.terraform_key.key_name

  associate_public_ip_address = true

  root_block_device {
  volume_size           = var.root_volume_size
  volume_type           = "gp3"
  encrypted             = true
  delete_on_termination = true
}
user_data = file("${path.module}/userdata.sh")

  tags = {
    Name = "${var.project_name}-ec2-${count.index + 1}"
  }

}