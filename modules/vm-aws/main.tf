data "aws_ami" "debian" {

  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name_pattern]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["136693071363"]
}

resource "aws_instance" "vm" {
  tags = {
    Name = var.name
  }
  ami                         = data.aws_ami.debian.id
  instance_type               = var.instance_type
  private_ip                  = var.ip_address
  subnet_id                   = var.subnet_id
  user_data                   = var.user_data
  user_data_replace_on_change = true
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = false
  metadata_options {
    http_tokens = "required"
  }
  root_block_device {
    volume_size = var.disk_gb
    encrypted   = true
  }
}