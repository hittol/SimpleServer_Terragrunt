include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  env_config = read_terragrunt_config(
    find_in_parent_folders("env.hcl")
  )
}

terraform {
  source = "../../../modules/vm"
}

dependency "rg" {
  config_path = "../rg"
  mock_outputs = {
    rg_name = {
      Hub     = "mock-hub-rg"
      Managed = "mock-managed-rg"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "vnet" {
  config_path = "../vnet"
  mock_outputs = {
    subnet_ids = {
      NATSubnet = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-hub-vnet/subnets/NATSubnet"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}


inputs = {
  managed_rg_name = dependency.rg.outputs.rg_name["Managed"]
  location        = include.root.locals.location

  key_path = "${get_terragrunt_dir()}/.key/nh_vm_key.pem"

  script_url = base64encode(
    file("${get_terragrunt_dir()}/script/configure-nva.sh")
  )

  vm_variable = {
    nva_vm = {
      name                = "VM-Terra-NAT-01"
      size                = "Standard_D2s_v5"
      subnet_id           = dependency.vnet.outputs.subnet_ids["NATSubnet"]
      resource_group_name = dependency.rg.outputs.rg_name["Hub"]
      private_ip          = "10.3.0.10"
      admin_username      = "azureadmin"

      ip_forwarding_enabled = true

      source_image = {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
      }

      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Premium_LRS"
        disk_size_gb         = 64
      }

      extension = {
        entra_login_enabled = true
        ama_enabled         = false
        scripts_enabled     = true
        script_url = base64encode(
          file("${get_terragrunt_dir()}/script/configure-nva.sh")
        )
      }
    }
  }
}
