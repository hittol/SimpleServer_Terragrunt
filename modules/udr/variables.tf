variable "location" {
  type = string
}

variable "udr_setting" {
  type = map(object({
    name    = string
    rg_name = string

    routes = map(object({
      address_prefix = string
      next_hop_type  = string
      next_hop_in_ip_address = optional(string)
    }))

    links = map(object({
      subnet_id = string
    }))
  }))
}