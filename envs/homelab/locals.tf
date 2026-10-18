locals {
  vm_names     = { for k, _ in var.vms : k => "${var.vmtag}-${k}" }
  cidr_prefix  = "/24"
  ssh_pub_keys = [for p in var.ssh_public_key_paths : trimspace(file(pathexpand(p)))]
}
