module "cloud_init" {
  source              = "../../modules/cloud-init"
  username            = var.username
  packages            = var.packages
  ssh_authorized_keys = local.ssh_pub_keys
  node_name           = var.node_name
  vm_id               = var.vm_id
  hostname            = local.vm_name
}