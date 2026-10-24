output "id" {
  value       = aws_instance.vm.id
  description = "AWS EC2 instance id"
}
output "ip" {
  value       = aws_instance.vm.private_ip
  description = "AWS EC2 private IP"
}
