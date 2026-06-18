resource "azurerm_private_dns_zone" "dns_zone" {
  for_each            = var.dns_setting
  
  name                = each.value.dns_name
  resource_group_name = each.value.rg_name
}

locals {
  dns_links = merge([
    for zone_key, zone in var.dns_setting : {
      for link_key, link in zone.links :
      "${zone_key}.${link_key}" => {
        zone_key            = zone_key
        resource_group_name = zone.resource_group_name
        link_name           = link.link_name
        vnet_id             = link.vnet_id
      }
    }
  ]...)
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_vnet" {
  for_each              = local.dns_links

  name                  = each.value.link_name
  resource_group_name   = each.value.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone[each.value.zone_key].name
  virtual_network_id    = each.value.vnet_id
}
