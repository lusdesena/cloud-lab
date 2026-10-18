module "vm" {
  source   = "../../modules/vm-proxmox"
  for_each = var.vms

  name       = local.vm_names[each.key]
  vm_id      = each.value.vm_id
  node_name  = var.node_name
  cpu        = var.cores
  memory     = var.memory_mb
  disk_gb    = var.disk_gb
  user_data  = module.cloud_init[each.key].user_data
  ip_address = each.value.ip_address
  gateway    = var.gateway
}
