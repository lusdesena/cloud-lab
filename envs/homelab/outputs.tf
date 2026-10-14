output "vm_name" {
  value       = proxmox_virtual_environment_vm.proxmox_vm.name
  description = "VM name"
}
output "vm_id" {
  value       = proxmox_virtual_environment_vm.proxmox_vm.vm_id
  description = "VM ID"
}
output "vm_ip" {
  value       = proxmox_virtual_environment_vm.proxmox_vm.initialization[0].ip_config[0].ipv4[0].address
  description = "VM IP address"
}