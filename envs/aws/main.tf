module "network" {
  source   = "../../modules/network-aws"
  name     = var.name
  vpc_cidr = "10.20.0.0/16"
  azs      = ["eu-north-1a", "eu-north-1b"]
}
resource "aws_security_group" "security_group" {
  name        = "${var.name}-sg"
  vpc_id      = module.network.vpc_id
  description = "APT SSM security_group"
  tags = {
    Name = "${var.name}-sg"
  }
}
resource "aws_vpc_security_group_egress_rule" "egress_web" {
  for_each          = toset(["80", "443"])
  security_group_id = aws_security_group.security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
}
module "cloud_init" {
  source   = "../../modules/cloud-init"
  username = var.username
  hostname = "${var.name}-web"
  packages = ["nginx", "wget"]
  extra_runcmd = [
    "wget -O /tmp/amazon-ssm-agent.deb https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb",
    "dpkg -i /tmp/amazon-ssm-agent.deb",
    "systemctl enable --now amazon-ssm-agent"
  ]
}
module "vm" {
  source = "../../modules/vm-aws"

  name               = "${var.name}-web"
  user_data          = module.cloud_init.user_data
  subnet_id          = module.network.private_subnets_ids["private-0"]
  security_group_ids = [aws_security_group.security_group.id]
  instance_type      = "t3.micro"

  depends_on = [module.network]
}