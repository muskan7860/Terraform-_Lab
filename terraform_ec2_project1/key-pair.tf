resource "aws_key_pair" "terraform_key" {
  key_name   = "terrra-key-ec2"
  public_key = file("${path.module}/terrra-key-ec2.pub")

  tags = {
    Name = "terrra-key-ec2"
  }
}