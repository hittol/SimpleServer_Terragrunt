output "nic_private_ips" {
  value = {
    for k, nic in azurerm_network_interface.nic : k => nic.private_ip_address
  }
}