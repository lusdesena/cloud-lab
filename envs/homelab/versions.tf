terraform {
  required_version = ">= 1.11"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.116.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}