provider "proxmox" {
  ssh {
    agent    = true
    username = "terraform"
    node {
      name    = var.node_name
      address = var.node_ip
    }
  }
}