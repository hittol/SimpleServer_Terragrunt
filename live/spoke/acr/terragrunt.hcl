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
  source = "../../../source/acr"
}


dependency "spoke_rg" {
  config_path = "../rg"
  mock_outputs = {
    rg_name = "mock-spoke-rg"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "vnet" {
  config_path = "../vnet"
  mock_outputs = {
    subnet_ids = {
      PESubnet = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/DBSubnet"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "privatedns" {
  config_path = "../privatedns"
  mock_outputs = {
    zone_ids   = {
      acr = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  location        = include.root.locals.location

  acr_setting = {
    aks = {
      acr_rg_name         = dependency.spoke_rg.outputs.rg_name["Spoke"]

      acr_name            = "terr2acr001"
      acr_sku             = "Premium"
      admin_enable        = false
      public_access       = false

      acr_pe_subnet_id    = dependency.vnet.outputs.subnet_ids["PESubnet"]

      zone_group          = {
        name              = "default"
        zone_ids          = dependency.privatedns.outputs.zone_ids["acr"]
      }
    }
  }
}
