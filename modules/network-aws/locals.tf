locals {
  private_subnets = { for i, az in var.azs : "private-${i}" => { az = az, cidr = cidrsubnet(var.vpc_cidr, 8, i) } }
  public_subnets  = { for i, az in var.azs : "public-${i}" => { az = az, cidr = cidrsubnet(var.vpc_cidr, 8, 100 + i) } }
}