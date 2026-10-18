module "vm" {
  source = "../../modules/vm-proxmox"

  name       = local.vm_name
  vm_id      = var.vm_id
  node_name  = var.node_name
  cpu        = var.cores
  memory     = var.memory_mb
  disk_gb    = var.disk_gb
  user_data  = module.cloud_init.user_data
  ip_address = var.ip_address
  gateway    = var.gateway
}
