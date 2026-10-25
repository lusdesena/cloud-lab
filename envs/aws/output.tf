output "private_subnets" {
  value       = module.network.private_subnets
  description = "Private subnets map"
}
output "public_subnets" {
  value       = module.network.public_subnets
  description = "Public subnets map"
}
output "vpc_id" {
  value       = module.network.vpc_id
  description = "VPC ID"
}
output "nat_public_ip" {
  value       = module.network.nat_public_ip
  description = "NAT public IP"
}
output "public_subnets_ids" {
  value       = module.network.public_subnets_ids
  description = "Public subnets IDs"
}
output "private_subnets_ids" {
  value       = module.network.private_subnets_ids
  description = "Private subnets IDs"
}
output "instance_id" {
  value       = module.vm.id
  description = "EC2 instance id (for aws ssm start-session)"
}
output "alb_dns_name" {
  value       = aws_lb.web.dns_name
  description = "ALB dns_name attribute"
}