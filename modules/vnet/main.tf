# ===================================================================
# Create VNet
# ===================================================================

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.location
  resource_group_name = var.rg_name
}

# ===================================================================
# Create Subnet
# ===================================================================

resource "azurerm_subnet" "subnet" {
  for_each                        = var.subnets
  name                            = each.key
  resource_group_name             = var.rg_name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = each.value.address_prefixes
  default_outbound_access_enabled = each.value.default_outbound_access_enabled
  service_endpoints               = each.value.service_endpoints
  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }
}

# ===================================================================
# Create NSG
# ===================================================================

resource "azurerm_network_security_group" "nsg" {
  for_each            = var.nsg_rule
  name                = each.key
  location            = var.location
  resource_group_name = var.rg_name

  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# ===================================================================
# Connect NSG to Subnet
# ===================================================================

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  for_each = {
    for k, v in var.subnets : k => v
    if try(v.nsg_key, null) != null
  }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_key].id
}