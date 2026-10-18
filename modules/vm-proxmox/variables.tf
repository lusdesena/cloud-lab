# --- Contrato común (ver modules/README.md) ---
variable "name" {
  type        = string
  description = "VM name"
}
variable "cpu" {
  type        = number
  default     = 1
  description = "VM cores"
}
variable "memory" {
  type        = number
  default     = 2048
  description = "VM memory in MB"
}
variable "disk_gb" {
  type        = number
  default     = 20
  description = "VM disk size in GB"
}
variable "user_data" {
  type        = string
  description = "Rendered cloud-config content (not a file ID)"
}
variable "ip_address" {
  type        = string
  default     = null
  description = "Fixed IPv4 without mask. null = DHCP"
}

# --- Específico de Proxmox ---
variable "vm_id" {
  type        = number
  description = "VM ID"
}
variable "node_name" {
  type        = string
  description = "Name of the Proxmox node"
}
variable "datastore_id" {
  type        = string
  default     = "local-zfs"
  description = "Datastore for the VM disk and the cloud-init drive"
}
variable "snippets_datastore_id" {
  type        = string
  default     = "local"
  description = "Datastore that holds snippets (must have the snippets content type)"
}
variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Network bridge"
}
variable "template_vm_id" {
  type        = number
  default     = 9000
  description = "VM ID of the template to clone"
}
variable "gateway" {
  type        = string
  default     = "192.0.2.1"
  description = "IPv4 gateway. Only used when ip_address is set"
}
variable "prefix_length" {
  type        = number
  default     = 24
  description = "Subnet prefix length. Only used when ip_address is set"
}
