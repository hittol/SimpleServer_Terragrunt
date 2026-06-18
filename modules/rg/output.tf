output "rg_name" {
  value = {
    for key, rg in azurerm_resource_group.rg :
    key => rg.name
  }
}

output "rg_id" {
  value = {
    for key, rg in azurerm_resource_group.rg :
    key => rg.id
  }
}