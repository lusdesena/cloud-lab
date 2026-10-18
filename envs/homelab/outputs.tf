output "vm_name" {
  value       = local.vm_name
  description = "VM name"
}
output "vm_id" {
  value       = var.vm_id
  description = "VM ID"
}
output "vm_ip" {
  value       = module.vm.ip
  description = "VM IP address"
}
