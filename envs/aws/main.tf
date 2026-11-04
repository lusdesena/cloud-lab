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
  description       = "Outbound TCP ${each.value} to the internet (apt and SSM agent download)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
}
resource "aws_vpc_security_group_egress_rule" "egress_alb" {
  security_group_id            = aws_security_group.alb.id
  description                  = "ALB to the instances on TCP 80"
  referenced_security_group_id = aws_security_group.apt_ssm.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}
resource "aws_vpc_security_group_ingress_rule" "ingress_alb" {
  #checkov:skip=CKV_AWS_260: public HTTP listener by design; there is no domain or ACM certificate to serve HTTPS
  security_group_id = aws_security_group.alb.id
  description       = "Public HTTP to the ALB"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "ingress_aptssm" {
  #checkov:skip=CKV_AWS_260: false positive, the source is the ALB security group (referenced_security_group_id), not 0.0.0.0/0
  security_group_id            = aws_security_group.apt_ssm.id
  description                  = "Instances accept TCP 80 only from the ALB security group"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}
resource "aws_lb" "web" {
  #checkov:skip=CKV_AWS_150: lab environment destroyed from CI; deletion protection would block destroy
  #checkov:skip=CKV_AWS_91: access logs need an extra S3 bucket and add nothing to the lab
  #checkov:skip=CKV2_AWS_28: a WAF has a fixed monthly cost, not justified in a lab
  #checkov:skip=CKV2_AWS_20: no HTTPS listener to redirect to, there is no domain or ACM certificate
  name               = "${var.name}-web-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = values(module.network.public_subnets_ids)
  security_groups    = [aws_security_group.alb.id]

  drop_invalid_header_fields = true

  tags = {
    Name = "${var.name}-web-lb"
  }
}
resource "aws_lb_target_group" "web" {
  #checkov:skip=CKV_AWS_378: ALB to instance traffic stays inside the private subnets; HTTPS needs a certificate the lab does not have
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
  #checkov:skip=CKV_AWS_2: no domain or ACM certificate, so the listener is HTTP
  #checkov:skip=CKV_AWS_103: no TLS listener, same reason as CKV_AWS_2
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
  instance_type      = "t3.medium"

  depends_on = [module.network]
}