locals {
  vm_name      = "${var.vmtag}-${var.vm_name}"
  cidr_prefix  = "/24"
  ssh_pub_keys = [for p in var.ssh_public_key_paths : trimspace(file(pathexpand(p)))]
}