# ===================================================================
# Create SSH Key
# ===================================================================

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = var.key_path
  file_permission = "0600"
}

resource "azurerm_ssh_public_key" "vm_ssh_key" {
  name                = "vm-admin-key"
  resource_group_name = var.managed_rg_name
  location            = var.location
  public_key          = tls_private_key.ssh_key.public_key_openssh
}

# ===================================================================

# ===================================================================
# Create NIC
# ===================================================================

resource "azurerm_network_interface" "nic" {
  for_each = var.vm_variable

  name                = "${each.value.name}-nic"
  location            = var.location
  resource_group_name = each.value.resource_group_name

  ip_forwarding_enabled = each.value.ip_forwarding_enabled

  ip_configuration {
    name                          = "primary"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = each.value.private_ip != null ? "Static" : "Dynamic"
    private_ip_address            = each.value.private_ip
  }
}

# ===================================================================

# ===================================================================
# Create VM
# ===================================================================

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = var.vm_variable

  name                = each.value.name
  location            = var.location
  resource_group_name = each.value.resource_group_name
  size                = each.value.size
  admin_username      = each.value.admin_username

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  os_disk {
    name                   = "${each.value.name}-osdisk"
    caching                = each.value.os_disk.caching
    storage_account_type   = each.value.os_disk.storage_account_type
    disk_size_gb           = each.value.os_disk.disk_size_gb
    disk_encryption_set_id = each.value.os_disk.disk_encryption_set_id
  }

  source_image_reference {
    publisher = each.value.source_image.publisher
    offer     = each.value.source_image.offer
    sku       = each.value.source_image.sku
    version   = each.value.source_image.version
  }

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = azurerm_ssh_public_key.vm_ssh_key.public_key
  }

  identity {
    type = "SystemAssigned"
  }
}

# ===================================================================

# ===================================================================
# Add Entra ID Login Extension
# ===================================================================

resource "azurerm_virtual_machine_extension" "entra_login" {
  for_each = {
    for key, vm in var.vm_variable :
    key => vm
    if vm.extension != null && vm.extension.entra_login_enabled
  }

  name                 = "AADSSHLoginForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm[each.key].id
  publisher            = "Microsoft.Azure.ActiveDirectory"
  type                 = "AADSSHLoginForLinux"
  type_handler_version = "1.0"
}

# ===================================================================

# ===================================================================
# VM Extenstion (Install AMA)
# ===================================================================

resource "azurerm_virtual_machine_extension" "AMA_extension" {
  for_each = {
    for key, vm in var.vm_variable :
    key => vm
    if vm.extension != null && vm.extension.ama_enabled
  }

  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.28"
  auto_upgrade_minor_version = true

  settings           = jsonencode({})
  protected_settings = jsonencode({})
}

# ===================================================================
# VM Custom Scripts Extenstion
# ===================================================================

resource "azurerm_virtual_machine_extension" "CustomScripts_extension" {
  for_each = {
    for key, vm in var.vm_variable :
    key => vm
    if vm.extension != null && vm.extension.scripts_enabled
  }

  name                       = "AzureCustomSciptsExtension"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm[each.key].id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  
  auto_upgrade_minor_version = true

  protected_settings = jsonencode({
    script = each.value.extension.script_url
  })
}