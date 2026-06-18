# ===================================================================
# VNET Peering
# ===================================================================

resource "azurerm_virtual_network_peering" "a_to_b" {
  name                      = var.a_to_b_name
  resource_group_name       = var.a_rg_name
  virtual_network_name      = var.a_vnet_name
  remote_virtual_network_id = var.b_vnet_id

  allow_forwarded_traffic      = var.allow_traffic
  allow_virtual_network_access = var.network_access
  allow_gateway_transit        = var.gateway_transit
}

resource "azurerm_virtual_network_peering" "b_to_a" {
  name                      = var.a_to_b_name
  resource_group_name       = var.b_rg_name
  virtual_network_name      = var.b_vnet_name
  remote_virtual_network_id = var.a_vnet_id

  allow_forwarded_traffic      = var.allow_traffic
  allow_virtual_network_access = var.network_access
  use_remote_gateways          = var.gateway_transit

  depends_on = [azurerm_virtual_network_peering.a_to_b]
}