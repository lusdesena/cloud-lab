resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {

    data = templatefile("${path.module}/user-data.yaml.tftpl", {
      username            = var.username
      packages            = var.packages
      ssh_authorized_keys = var.ssh_authorized_keys
      hostname = var.hostname
    })
    file_name = "cloud-config-${var.vm_id}.yml"
  }
}