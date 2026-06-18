variable "location" {
  type = string
}

variable "rg_name" {
  type = string
}

# ===================================================================
# VNet
# ===================================================================

variable "vnet_name" {
  type = string
}

variable "vnet_address_space" {
  type = list(string)
}

variable "subnets" {
  type = map(object({
    address_prefixes                = list(string)
    nsg_key                         = optional(string)
    default_outbound_access_enabled = optional(bool, false)
    service_endpoints               = optional(list(string))    
    delegation = optional(object({
      name = string
      service_delegation = object({
        name    = string
        actions = list(string)
      })
    }))
  }))
}

# ===================================================================
# NSG
# ===================================================================

variable "nsg_rule" {
  type = map(object({
    rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = optional(string, "*")
      destination_port_range     = string
      source_address_prefix      = optional(string, "*")
      destination_address_prefix = optional(string, "*")
    }))
  }))
  default = {}
}