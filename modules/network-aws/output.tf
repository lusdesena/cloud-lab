output "private_subnets" {
  value       = local.private_subnets
  description = "Private subnets map"
}
output "public_subnets" {
  value       = local.public_subnets
  description = "Public subnets map"
}
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}
output "public_subnets_ids" {
  value       = { for k, s in aws_subnet.public : k => s.id }
  description = "Public subnets IDs"
}
output "private_subnets_ids" {
  value       = { for k, s in aws_subnet.private : k => s.id }
  description = "Private subnets IDs"
}
output "nat_public_ip" {
  value = aws_eip.main.public_ip
}