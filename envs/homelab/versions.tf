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
  backend "s3" {
    bucket       = "cloud-lab-tfstate-035074950804-eu-north-1"
    key          = "homelab/terraform.tfstate"
    region       = "eu-north-1"
    use_lockfile = true
    encrypt      = true
  }
}