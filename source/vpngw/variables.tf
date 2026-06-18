variable "rg_name" {
  type = string
}

variable "location" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "pip_sku" {
  type = string
}

variable "pip_zones" {
  type = list(string)
}

variable "public_ip_allocation_method" {
  type = string
  validation {
    condition     = contains(["Static", "Dynamic"], var.public_ip_allocation_method)
    error_message = "Wrong Value : allocation_method must has 'Static' or 'Dynamic'."
  }
}

variable "active_active_enabled" {
  type = bool
}

variable "bgp_enabled" {
  type = bool
}

variable "vpngateway_name" {
  type = string
}

variable "vpn_sku" {
  type = string
}

variable "private_ip_allocation_method" {
  type = string
  validation {
    condition     = contains(["Static", "Dynamic"], var.private_ip_allocation_method)
    error_message = "Wrong Value : allocation_method must has 'Static' or 'Dynamic'."
  }
}