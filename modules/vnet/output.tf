output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "subnet_ids" {
  value = {
    for k, v in azurerm_subnet.subnet : k => v.id
  }
}

output "hub_subnet_cidrs" {
  value = { for k, s in azurerm_subnet.subnet : k => s.address_prefixes[0] }
}