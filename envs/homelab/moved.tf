moved {
  from = proxmox_virtual_environment_vm.proxmox_vm
  to   = module.vm.proxmox_virtual_environment_vm.vm
}

moved {
  from = module.cloud_init.proxmox_virtual_environment_file.cloud_config
  to   = module.vm.proxmox_virtual_environment_file.cloud_config
}
