variable "location" {
  type = string
}

variable "managed_rg_name" {
  type = string
}

variable "key_path" {
  type = string
}

# ===================================================================
# VM Settings
# ===================================================================

variable "vm_variable" {
  type = map(object({
    name                = string
    size                = string
    subnet_id           = string
    private_ip          = optional(string)
    admin_username      = string
    resource_group_name = string

    nva_configuration_enabled = optional(bool, false)
    ip_forwarding_enabled     = optional(bool, false)

    source_image = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })

    os_disk = object({
      caching                = string
      storage_account_type   = string
      disk_size_gb           = number
      disk_encryption_set_id = optional(string)
    })

    extension = optional(object({
      entra_login_enabled = optional(bool, false)
      ama_enabled         = optional(bool, false)
      scripts_enabled     = optional(bool, false)
      script_url          = optional(string)
    }))
  }))
}

