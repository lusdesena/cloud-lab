resource "proxmox_virtual_environment_file" "cloud_config" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  source_raw {
    data      = var.user_data
    file_name = "cloud-config-${var.vm_id}.yml"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id

  agent {
    enabled = true
    timeout = "2m"
  }
  cpu {
    cores = var.cpu
  }
  memory {
    dedicated = var.memory
  }
  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = var.disk_gb
  }
  network_device {
    model  = "virtio"
    bridge = var.bridge
  }
  clone {
    vm_id        = var.template_vm_id
    datastore_id = var.datastore_id
  }
  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = proxmox_virtual_environment_file.cloud_config.id

    ip_config {
      ipv4 {
        address = var.ip_address == null ? "dhcp" : "${var.ip_address}/${var.prefix_length}"
        gateway = var.ip_address == null ? null : var.gateway
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.ip_address == null || can(cidrhost("${var.ip_address}/${var.prefix_length}", 0))
      error_message = "This must be a valid IPv4 address without mask. Example: 192.0.2.100"

    }
    precondition {
      condition     = var.ip_address == null || can(cidrhost("${var.ip_address}/${var.prefix_length}", 0)) && cidrhost("${var.ip_address}/${var.prefix_length}", 0) == cidrhost("${var.gateway}/${var.prefix_length}", 0)
      error_message = "ip_address ${var.ip_address}/${var.prefix_length} is not in the same subnet as gateway ${var.gateway}/${var.prefix_length}."
    }
    postcondition {
      condition     = var.ip_address == null || contains(flatten(self.ipv4_addresses), var.ip_address)
      error_message = "The IP address ${var.ip_address} is not in the list of IP addresses reported by the guest agent: ${join(", ", flatten(self.ipv4_addresses))}."
    }
  }
}
