output "cloud_config_id" {
  value       = proxmox_virtual_environment_file.cloud_config.id
  description = "snippet ID of the cloud-config file in Proxmox"
}