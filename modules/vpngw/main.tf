# ===================================================================
# Create Gateway Pip
# ===================================================================

resource "azurerm_public_ip" "gateway_pip" {
  name                = "${var.vpngateway_name}-pip"
  location            = var.location
  resource_group_name = var.rg_name
  sku                 = var.pip_sku
  zones               = var.pip_zones

  allocation_method   = var.public_ip_allocation_method
}

# ===================================================================


# ===================================================================
# Create Virtual Network Gateway
# ===================================================================

resource "azurerm_virtual_network_gateway" "vnet_gateway" {
  name                = var.vpngateway_name
  location            = var.location
  resource_group_name = var.rg_name

  type                = "Vpn"
  vpn_type            = "RouteBased"

  active_active       = var.active_active_enabled
  bgp_enabled         = var.bgp_enabled
  sku                 = var.vpn_sku

  ip_configuration {
    name                 = "vnetGatewayConfig"
    public_ip_address_id = azurerm_public_ip.gateway_pip.id
    subnet_id            = var.subnet_id

    private_ip_address_allocation = var.private_ip_allocation_method
  }
}

# ===================================================================