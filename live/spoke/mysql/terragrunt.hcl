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
  source = "../../../source/mysql"
}

dependency "man_rg" {
  config_path = "../../hub/rg"
  mock_outputs = {
    rg_name = {
      Managed   = "mock-managed-rg"
    }
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

dependency "vnet" {
  config_path = "../vnet"
  mock_outputs = {
    dbsubnet_id   = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/DBSubnet"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "privatedns" {
  config_path = "../privatedns"
  mock_outputs = {
    zone_ids   = {
      mysql = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.mysql.database.azure.com"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  location        = include.root.locals.location

  mysql_setting = {
    spoke_sql = {
      managed_rg_name     = dependency.man_rg.outputs.rg_name["Managed"]

      sql_rg_name         = dependency.spoke_rg.outputs.rg_name["Spoke"]
      sql_name            = "sqlterspoke01"
      mysql_login         = "testuser"
      backup_day          = 7
      dbsubnet_id         = dependency.vnet.outputs.subnet_ids["DBSubnet"]
      backup_grs          = false
      dns_zone_id         = dependency.privatedns.outputs.zone_ids["mysql"]
      mysql_sku           = "B_Standard_B1ms"
      mysql_version       = "8.0.21"

      storage             = {
        mysql_gbsize      = 64
      }

      identity            = {
        type              = "UserAssigned"
      }
    }
  }
}
