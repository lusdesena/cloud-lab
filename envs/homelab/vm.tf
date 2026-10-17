resource "proxmox_virtual_environment_vm" "proxmox_vm" {
  name      = local.vm_name
  node_name = "pve"
  vm_id     = var.vm_id

  agent {
    enabled = true
    timeout = "2m"
  }
  cpu {
    cores = var.cores
  }
  memory {
    dedicated = var.memory_mb
  }
  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = var.disk_gb
  }
  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }
  clone {
    vm_id        = 9000
    datastore_id = "local-zfs"
  }
  initialization {
    datastore_id      = "local-zfs"
    user_data_file_id = module.cloud_init.cloud_config_id

    ip_config {
      ipv4 {
        address = "${var.ip_address}${local.cidr_prefix}"
        gateway = var.gateway
      }
    }
  }
}