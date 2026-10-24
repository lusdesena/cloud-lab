# --- Contrato común (ver modules/README.md) ---
variable "name" {
  type        = string
  description = "VM name"
}
variable "disk_gb" {
  type        = number
  default     = 8
  description = "VM disk size in GB"
}
variable "user_data" {
  type        = string
  description = "Rendered cloud-config content (not a file ID)"
}
variable "ip_address" {
  type        = string
  default     = null
  description = "AWS EC2 static private IP"
  validation {
    condition     = var.ip_address == null || can(cidrhost("${var.ip_address}/32", 0))
    error_message = "This must be a valid IPv4 address without mask. Example: 192.0.2.100"
  }
}
# --- Específico AWS ---
variable "subnet_id" {
  type        = string
  description = "EC2 subnet id"
}
variable "security_group_ids" {
  type        = list(string)
  description = "EC2 associated security groups IDs"
}
variable "instance_type" {
  type        = string
  description = "EC2 instance type from AWS catalogue"
}
variable "ami_name_pattern" {
  type        = string
  description = "EC2 AMI image name pattern"
  default     = "debian-13-amd64-20260327*"
}

