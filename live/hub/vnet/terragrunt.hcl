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
  source = "../../../source/vnet"
}

dependency "rg" {
  config_path = "../rg"
  mock_outputs = {
    rg_name = {
      Hub   = "mock-hub-rg"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  rg_name             = dependency.rg.outputs.rg_name["Hub"]
  location            = include.root.locals.location

  vnet_name           = "VNET-Terra-Hub"
  vnet_address_space  = ["10.3.0.0/21"]
  subnets = {
    "NATSubnet" = {
      address_prefixes                = ["10.3.0.0/28"]
      nsg_key                         = "NSG-NATSubnet-Hub"
      default_outbound_access_enabled = false
    }
    "PrivateSubnet" = {
      address_prefixes                = ["10.3.0.16/28"]
      default_outbound_access_enabled = false
    }
    "HubSubnet" = {
      address_prefixes                = ["10.3.0.64/26"]
      nsg_key                         = "NSG-HubSubnet-Hub"
      default_outbound_access_enabled = false
    }
    "GatewaySubnet" = {
      address_prefixes                = ["10.3.1.0/24"]
      default_outbound_access_enabled = true
    }
    "ApplicationGatewaySubnet" = {
      address_prefixes                = ["10.3.2.0/24"]
      default_outbound_access_enabled = true
    }
  }

  nsg_rule = {
    "NSG-HubSubnet-Hub" = {
      rules = [
        {
          name                       = "Allow_SSH_Inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "22"
          source_address_prefix      = "172.20.22.0/24"
          destination_address_prefix = "10.3.0.70"
        }
      ]
    }
    "NSG-NATSubnet-Hub" = {
      rules = [
        {
          name                       = "Allow_SSH_Inbound"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          destination_port_range     = "22"
          source_address_prefix      = "172.20.22.0/24"
          destination_address_prefix = "10.3.0.10"
        }
      ]
    }
  }
}
