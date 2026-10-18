variable "vmtag" {
  type        = string
  description = "VM tag"
  default     = "tf"
  validation {
    condition     = var.vmtag == "tf"
    error_message = "VM tag must be 'tf'"
  }
}
variable "cores" {
  type        = number
  default     = 1
  description = "VM cores"
  validation {
    condition     = var.cores == floor(var.cores)
    error_message = "Insert integer value for cores"
  }
}
variable "memory_mb" {
  type        = number
  default     = 2048
  description = "VM memory in MB"
  validation {
    condition     = var.memory_mb >= 1024
    error_message = "Memory in MB must be equal to or greater than 1024"
  }
}
variable "disk_gb" {
  type        = number
  default     = 20
  description = "VM disk size in GB"
}
variable "gateway" {
  type        = string
  description = "IPv4 gateway of the VM"
  default     = "192.0.2.1"
}
variable "ssh_public_key_paths" {
  type        = list(string)
  description = "Paths to the SSH public keys"
}
variable "node_ip" {
  type        = string
  description = "IP address of the Proxmox node"
}
variable "node_name" {
  type        = string
  description = "Name of the Proxmox node"
}
variable "packages" {
  type        = list(string)
  description = "List of packages to install on the VM"
  default     = ["nginx", "qemu-guest-agent"]
}
variable "username" {
  type        = string
  description = "Username for the VM"
  validation {
    condition     = length(var.username) > 0 && var.username != "root"
    error_message = "Username cannot be root or empty."
  }
}
variable "vms" {
  type = map(object({
    vm_id      = number
    ip_address = string
  }))
  description = "VMs to create, keyed by name without the 'tf-' prefix (it is added automatically). ip_address is the IPv4 without subnet mask."
  validation {
    condition     = alltrue([for k, _ in var.vms : !startswith(k, "tf-")])
    error_message = "Don't include the prefix 'tf-' in the VM name. It will be added automatically."
  }
  validation {
    condition     = alltrue([for _, vm in var.vms : vm.vm_id >= 300 && vm.vm_id <= 309 && vm.vm_id == floor(vm.vm_id)])
    error_message = "VM_ID must be between 300 and 309 and without decimals"
  }
  validation {
    condition     = length(distinct([for _, vm in var.vms : vm.vm_id])) == length(var.vms)
    error_message = "VM IDs must be unique"
  }
  validation {
    condition     = alltrue([for _, vm in var.vms : can(regex("^192\\.0\\.2\\.(15[0-9])$", vm.ip_address))])
    error_message = "The allowed IP address range is from 192.0.2.150 to 192.0.2.159"
  }
  validation {
    condition     = length(distinct([for _, vm in var.vms : vm.ip_address])) == length(var.vms)
    error_message = "IP addresses must be unique"
  }
}
