variable "dns_setting" {
  type = map(object({
    dns_name            = string
    resource_group_name = string
    links = map(object({
      link_name = string
      vnet_id   = string
    }))
  }))
} 