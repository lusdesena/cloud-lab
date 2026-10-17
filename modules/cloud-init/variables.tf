variable "username" {
  type        = string
  description = "Username for the VM"
  validation {
    condition     = length(var.username) > 0 && var.username != "root"
    error_message = "Username cannot be root or empty."
  }
}
variable "packages" {
  type        = list(string)
  description = "List of packages to install on the VM"
}
variable "ssh_authorized_keys" {
  type        = list(string)
  description = "List of SSH public keys to add to the VM"
}
variable "node_name" {
  type        = string
  description = "Name of the Proxmox node"
}
variable "vm_id" {
  type        = number
  description = "VM ID"
}
variable "hostname" {
  type        = string
  description = "Hostname for the VM"
}