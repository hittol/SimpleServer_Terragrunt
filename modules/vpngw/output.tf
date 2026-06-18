output "gateway_public_ip_address" {
  value = azurerm_public_ip.gateway_pip.ip_address
}

output "vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.vnet_gateway.id
}