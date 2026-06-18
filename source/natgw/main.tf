# ===================================================================
# Create PIP
# ===================================================================

resource "azurerm_public_ip" "natgw_pip" {
  name                = "${var.natgw_name}-pip"
  location            = var.location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ===================================================================
# Create NAT Gateway
# ===================================================================

resource "azurerm_nat_gateway" "natgw" {
  name                = var.natgw_name
  location            = var.location
  resource_group_name = var.rg_name
}

# ===================================================================
# Setting NAT Gateway Association
# ===================================================================

resource "azurerm_nat_gateway_public_ip_association" "ass-ip" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.natgw_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "ass-nat-subnet" {
  for_each = var.subnet_ids

  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.natgw.id
}