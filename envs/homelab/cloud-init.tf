module "cloud_init" {
  source   = "../../modules/cloud-init"
  for_each = var.vms

  username            = var.username
  packages            = var.packages
  ssh_authorized_keys = local.ssh_pub_keys
  hostname            = local.vm_names[each.key]
}
