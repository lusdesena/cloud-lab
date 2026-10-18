output "id" {
  value       = proxmox_virtual_environment_vm.vm.id
  description = "VM ID in Proxmox"
}
output "ip" {
  value       = var.ip_address != null ? var.ip_address : try(proxmox_virtual_environment_vm.vm.ipv4_addresses[1][0], null)
  description = "VM IP address: the fixed one, or the one reported by the guest agent"
}
