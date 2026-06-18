# ===================================================================
# Create ACR
# ===================================================================

resource "azurerm_container_registry" "acr" {
  for_each                      = var.acr_setting

  name                          = each.value.acr_name
  resource_group_name           = each.value.acr_rg_name
  location                      = var.location
  sku                           = each.value.acr_sku
  admin_enabled                 = each.value.admin_enable
  public_network_access_enabled = each.value.public_access
}

# ===================================================================
# Private Link
# ===================================================================

resource "azurerm_private_endpoint" "acr-pe" {
  for_each                          = var.acr_setting

  name                              = "pe-${each.value.acr_name}"
  resource_group_name               = each.value.acr_rg_name
  location                          = var.location
  subnet_id                         = each.value.acr_pe_subnet_id

  private_dns_zone_group {
    name                            = each.value.zone_group.name
    private_dns_zone_ids            = [each.value.zone_group.zone_ids]
  }

  private_service_connection {
    name                            = "pe-conn-${each.value.acr_name}"
    private_connection_resource_id  = azurerm_container_registry.acr[each.key].id
    subresource_names = ["registry"]
    is_manual_connection = false
  }
}

# ===================================================================