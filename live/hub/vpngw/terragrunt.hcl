include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../modules/vpngw"
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

dependency "vnet" {
  config_path = "../vnet"
  mock_outputs = {
    subnet_ids = {
      GatewaySubnet = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-hub-vnet/subnets/GatewaySubnet"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  location                      = include.root.locals.location

  rg_name                       = dependency.rg.outputs.rg_name["Hub"]
  subnet_id                     = dependency.vnet.outputs.subnet_ids["GatewaySubnet"]
  pip_sku                       = "Standard"
  pip_zones                     = ["1", "2", "3"]

  public_ip_allocation_method   = "Static"

  active_active_enabled         = false
  bgp_enabled                   = false
  vpngateway_name               = "VPNGW-Terra-Hub"
  vpn_sku                       = "VpnGw1AZ"

  private_ip_allocation_method  = "Dynamic"
}


