variable "name" {
  type        = string
  description = "Network name"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC network CIDR"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Not a valid CIDR"
  }

  validation {
    condition     = tonumber(split("/", var.vpc_cidr)[1]) >= 16 && tonumber(split("/", var.vpc_cidr)[1]) <= 20
    error_message = "The prefix length must be between 16 and 20"
  }

}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Availability Zones has to be equal or greater than 2"
  }

}
