locals {

  instance_type = {
    default = "t3.micro"
    dev     = "t3.micro"
    stage   = "t3.micro"
    prod    = "m7i-flex.large"
  }

  instance_count = {
    default = 1
    dev     = 1
    stage   = 1
    prod    = 1
  }

  root_volume_size = {
    default = 8
    dev     = 8
    stage   = 8
    prod    = 14
  }
  associate_public_ip = {
    default = true
    dev     = true
    stage   = true
    prod    = false
  }

  selected_azs = slice(
    data.aws_availability_zones.available.names,
    0,
    var.availability_zone_count
  )
}

