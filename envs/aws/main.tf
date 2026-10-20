module "network" {
  source   = "../../modules/network-aws"
  name     = var.name
  vpc_cidr = "10.20.0.0/16"
  azs      = ["eu-north-1a", "eu-north-1b"]
}