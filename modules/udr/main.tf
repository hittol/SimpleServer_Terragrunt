resource "azurerm_route_table" "udr" {
  for_each            = var.udr_setting

  name                = each.value.name
  location            = var.location
  resource_group_name = each.value.rg_name

  dynamic "route" {
    for_each = each.value.routes
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
}

locals {
  udr_links = merge([
    for udr_key, udr in var.udr_setting : {
      for link_key, link in udr.links :
      "${udr_key}.${link_key}" => {
        udr_key               = udr_key
        subnet_id             = link.subnet_id
      }
    }
  ]...)
}

resource "azurerm_subnet_route_table_association" "udr_associate" {
  for_each        = local.udr_links

  subnet_id       = each.value.subnet_id
  route_table_id  = azurerm_route_table.udr[each.value.udr_key].id
}