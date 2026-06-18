variable "location" {
  type = string
}

variable "acr_setting" {
  type = map(object({
    acr_rg_name             = string
    acr_name                = string
    acr_sku                 = string
    admin_enable            = bool
    public_access           = bool

    acr_pe_subnet_id        = string

    zone_group              = object({
      name                  = string
      zone_ids              = string
    })
  }))
} 