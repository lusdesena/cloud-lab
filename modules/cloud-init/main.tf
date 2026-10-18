locals {
  user_data = templatefile("${path.module}/user-data.yaml.tftpl", {
    username            = var.username
    packages            = var.packages
    ssh_authorized_keys = var.ssh_authorized_keys
    hostname            = var.hostname
  })
}
