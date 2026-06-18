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
  source = "../../../modules/vnet"
}

dependency "rg" {
  config_path = "../rg"
  mock_outputs = {
    rg_name = {
      Spoke   = "mock-spoke-rg"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  rg_name             = dependency.rg.outputs.rg_name["Spoke"]
  location            = include.root.locals.location

  vnet_name           = "VNET-Terra-Spoke"
  vnet_address_space  = ["10.3.16.0/21"]
  subnets = {
    "AKSSubnet" = {
      address_prefixes                = ["10.3.16.0/23"]
      default_outbound_access_enabled = false
    }
    "DBSubnet"  = {
      address_prefixes                = ["10.3.19.0/24"]
      default_outbound_access_enabled = false
      service_endpoints               = ["Microsoft.Storage"]
      delegation = {
        name = "fs"
        service_delegation = {
          name    = "Microsoft.DBforMySQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
          ]
        }
      }
    }
    "PESubnet" = {
      address_prefixes                = ["10.3.20.0/27"]
      default_outbound_access_enabled = false
    }
  }
}
