module "cloud_init" {
  source              = "../../modules/cloud-init"
  username            = var.username
  packages            = var.packages
  ssh_authorized_keys = local.ssh_pub_keys
  hostname            = local.vm_name
}
