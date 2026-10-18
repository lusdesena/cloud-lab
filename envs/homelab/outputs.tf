output "vms" {
  value = { for k, vm in module.vm : k => {
    name  = local.vm_names[k]
    vm_id = vm.id
    ip    = vm.ip
  } }
  description = "Created VMs, keyed by name without the 'tf-' prefix"
}
