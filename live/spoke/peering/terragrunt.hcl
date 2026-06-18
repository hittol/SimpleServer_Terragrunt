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
  source = "../../../modules/peering"
}

dependency "hub_rg" {
  config_path = "../../hub/rg"
  mock_outputs = {
    rg_name = {
      Hub   = "mock-hub-rg"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "hub_vnet" {
  config_path = "../../hub/vnet"
  mock_outputs = {
    vnet_name = "mock-hub-vnet"
    vnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-hub-vnet"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "spoke_rg" {
  config_path = "../rg"
  mock_outputs = {
    rg_name = {
      Spoke   = "mock-spoke-rg"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "spoke_vnet" {
  config_path = "../vnet"
  mock_outputs = {
    vnet_name = "mock-spoke-vnet"
    vnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  a_to_b_name         = "Hub-Spoke-Peering"

  a_rg_name           = dependency.hub_rg.outputs.rg_name["Hub"]
  a_vnet_name         = dependency.hub_vnet.outputs.vnet_name
  a_vnet_id           = dependency.hub_vnet.outputs.vnet_id

  b_rg_name           = dependency.spoke_rg.outputs.rg_name["Spoke"]
  b_vnet_name         = dependency.spoke_vnet.outputs.vnet_name
  b_vnet_id           = dependency.spoke_vnet.outputs.vnet_id
  
  allow_traffic       = "true"
  network_access      = "true"
  gateway_transit     = "false"
}