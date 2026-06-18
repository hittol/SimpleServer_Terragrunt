output "zone_ids" {
  value = {
    for k, v in azurerm_private_dns_zone.dns_zone : k => v.id
  }
}