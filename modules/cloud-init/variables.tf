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
  default     = []
  description = "List of packages to install on the VM"
}
variable "ssh_authorized_keys" {
  type        = list(string)
  default     = []
  description = "List of SSH public keys to add to the VM"
}
variable "hostname" {
  type        = string
  description = "Hostname for the VM"
}
variable "extra_runcmd" {
  type        = list(string)
  default     = []
  description = "runcmd that may vary depending on the provider"
}