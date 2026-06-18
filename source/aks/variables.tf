variable "managed_rg_name" {
  type = string  
}

variable "location" {
  type = string  
}

variable "key_path" {
  type = string
}

variable "aks_setting" {
  type = map(object({
    managed_rg_name         = string

    rg_name                 = string
    node_rg_name            = string
    aks_name                = string
    scope_dns_id            = string
    scope_vnet_id           = string
    aks_tier                = string

    oidc_enabled            = bool
    workload_enabled        = bool
    private_cluster_enabled = bool
    public_fqdn_enabled     = bool
    policy_enabled          = bool

    private_dns_zone_id     = string
    dns_prefix              = string

    default_node            = object({
      name                  = string
      node_count            = number
      vm_size               = string
      zones                 = list(string)
      vnet_subnet_id        = string
    })

    network_profile         = object({
      plugin                = string
      plugin_mode           = optional(string)
      policy                = optional(string)
      data_plane            = optional(string)
      lb_sku                = string
      service_cidr          = string
      dns_ip                = string
    })

    linux_profile           = object({
      username              = string
    })

    scope_acr_id            = string

    node_pools              = optional(map(object({
      name                  = string
      vm_size               = string
      node_count            = optional(number, 1)
      zones                 = optional(list(string))
      vnet_subnet_id        = string
      mode                  = optional(string, "User")
      node_labels           = optional(map(string))
      node_taints           = optional(list(string))
    })))
  }))
}
