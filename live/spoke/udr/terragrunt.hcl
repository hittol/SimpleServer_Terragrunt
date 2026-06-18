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
  source = "../../../modules/udr"
}

dependency "managed_rg" {
  config_path = "../../hub/rg"
  mock_outputs = {
    rg_name = {
      Managed   = "mock-managed-rg"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "spoke_vnet" {
  config_path = "../vnet"
  mock_outputs = {
    subnet_ids = {
      AKSSubnet = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/DBSubnet"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "nva_ip" {
  config_path = "../../hub/vm"
  mock_outputs = {
    nic_private_ips = {
      nva_vm = "11.11.11.11"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  location        = include.root.locals.location

  udr_setting = {
    udr_01    = {
      name                = "UDR-Terra-Managed"
      rg_name             = dependency.managed_rg.outputs.rg_name["Managed"]

      routes    = {
        public  = {
          address_prefix          = "0.0.0.0/0"
          next_hop_type           = "VirtualAppliance"
          next_hop_in_ip_address  = dependency.nva_ip.outputs.nic_private_ips["nva_vm"]
        }
        test    = {
          address_prefix          = "1.1.1.1/32"
          next_hop_type           = "VirtualAppliance" 
          next_hop_in_ip_address  = dependency.nva_ip.outputs.nic_private_ips["nva_vm"]
        }
      }

      links = {
        aks = {
          subnet_id               = dependency.spoke_vnet.outputs.subnet_ids["AKSSubnet"]
        }
      }
    }
  }
}