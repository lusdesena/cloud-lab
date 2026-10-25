module "network" {
  source   = "../../modules/network-aws"
  name     = var.name
  vpc_cidr = "10.20.0.0/16"
  azs      = ["eu-north-1a", "eu-north-1b"]
}
resource "aws_security_group" "apt_ssm" {
  name        = "${var.name}-aptssm-sg"
  vpc_id      = module.network.vpc_id
  description = "APT SSM security_group"
  tags = {
    Name = "${var.name}-aptssm-sg"
  }
}
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  vpc_id      = module.network.vpc_id
  description = "ALB security-group"
  tags = {
    Name = "${var.name}-alb-sg"
  }
}
resource "aws_vpc_security_group_egress_rule" "egress_web" {
  for_each          = toset(["80", "443"])
  security_group_id = aws_security_group.apt_ssm.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
}
resource "aws_vpc_security_group_egress_rule" "egress_alb" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.apt_ssm.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}
resource "aws_vpc_security_group_ingress_rule" "ingress_alb" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "ingress_aptssm" {
  security_group_id            = aws_security_group.apt_ssm.id
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}
resource "aws_lb" "web" {
  name               = "${var.name}-web-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = values(module.network.public_subnets_ids)
  security_groups    = [aws_security_group.alb.id]
  tags = {
    Name = "${var.name}-web-lb"
  }
}
resource "aws_lb_target_group" "web" {
  name     = "${var.name}-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id
  health_check {
    path              = "/"
    matcher           = "200"
    interval          = 10
    healthy_threshold = 2
  }
  tags = {
    Name = "${var.name}-web-tg"
  }
}
resource "aws_lb_target_group_attachment" "web" {
  target_group_arn = aws_lb_target_group.web.arn
  target_id        = module.vm.id
  port             = 80
}
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}
module "cloud_init" {
  source   = "../../modules/cloud-init"
  username = var.username
  hostname = "${var.name}-web"
  packages = ["nginx", "wget"]
  extra_runcmd = [
    "systemctl enable --now nginx.service",
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
  security_group_ids = [aws_security_group.apt_ssm.id]
  instance_type      = "t3.micro"

  depends_on = [module.network]
}