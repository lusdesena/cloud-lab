resource "proxmox_virtual_environment_vm" "tf_test_01" {
  name      = "tf-test-01"
  node_name = "pve"
  vm_id     = 300

  agent {
    enabled = true
    timeout = "2m"
  }
  cpu {
    cores = 1
  }
  memory {
    dedicated = 2048
  }
  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    size         = 20
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
    datastore_id = "local-zfs"
    ip_config {
      ipv4 {
        address = "192.0.2.150/24"
        gateway = "192.0.2.1"
      }
    }
    user_account {
      username = "abel"
      keys     = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
    }
  }
}