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
  source = "../../../modules/privatedns"
}

dependency "managed_rg" {
  config_path = "../../hub/rg"
  mock_outputs = {
    rg_name = {
      Hub   = "mock-managed-rg"
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

dependency "spoke_vnet" {
  config_path = "../../spoke/vnet"
  mock_outputs = {
    vnet_name = "mock-spoke-vnet"
    vnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {

  dns_setting = {
    "mysql" = {
      dns_name            = "privatelink.mysql.database.azure.com"
      resource_group_name = dependency.managed_rg.outputs.rg_name["Managed"]
      links = {
        hub = {
          link_name       = "link-hub-vnet"
          vnet_id         = dependency.hub_vnet.outputs.vnet_id
        }
        spoke = {
          link_name       = "link-spoke-vnet"
          vnet_id         = dependency.spoke_vnet.outputs.vnet_id
        }
      }
    }
    "aks" = {
      dns_name            = "privatelink.koreacentral.azmk8s.io"
      resource_group_name = dependency.managed_rg.outputs.rg_name["Managed"]
      links = {
        hub = {
          link_name       = "link-hub-vnet"
          vnet_id         = dependency.hub_vnet.outputs.vnet_id
        }
        spoke = {
          link_name       = "link-spoke-vnet"
          vnet_id         = dependency.spoke_vnet.outputs.vnet_id
        }
      }
    }
    "acr" = {
      dns_name            = "privatelink.azurecr.io"
      resource_group_name = dependency.managed_rg.outputs.rg_name["Managed"]
      links = {
        hub = {
          link_name       = "link-hub-vnet"
          vnet_id         = dependency.hub_vnet.outputs.vnet_id
        }
        spoke = {
          link_name       = "link-spoke-vnet"
          vnet_id         = dependency.spoke_vnet.outputs.vnet_id
        }
      }
    }
  }
}