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
  source = "../../../source/aks"
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
    vnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet"
    subnet_ids = {
      AKSSubnet = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-spoke-vnet/subnets/DBSubnet"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "privatedns" {
  config_path = "../privatedns"
  mock_outputs = {
    zone_ids   = {
      aks = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/privateDnsZones/privatelink.koreacentral.azmk8s.io"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "acr" {
  config_path = "../acr"
  mock_outputs = {
    acr_ids   = {
      aks = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.ContainerRegistry/registries/acrmock001"
    }
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state = "shallow"
}

inputs = {
  location                    = include.root.locals.location
  managed_rg_name             = dependency.man_rg.outputs.rg_name["Managed"]
  key_path                    = "${get_terragrunt_dir()}/.key/nh_aks_key.pem"

  aks_setting                 = {
    front_aks                 = {
      managed_rg_name         = dependency.man_rg.outputs.rg_name["Managed"]

      rg_name                 = dependency.spoke_rg.outputs.rg_name["Spoke"]
      node_rg_name            = "Managed-Front-AKS-RG"
      aks_name                = "Front-AKS-Spoke"
      scope_dns_id            = dependency.privatedns.outputs.zone_ids["aks"]
      scope_vnet_id           = dependency.vnet.outputs.vnet_id
      aks_tier                = "Standard"

      oidc_enabled            = true
      workload_enabled        = true
      private_cluster_enabled = true
      public_fqdn_enabled     = false
      policy_enabled          = false

      private_dns_zone_id     = dependency.privatedns.outputs.zone_ids["aks"]
      dns_prefix              = "front"

      default_node            = {
        name                  = "syspool"
        node_count            = 1
        vm_size               = "Standard_B2s"
        zones                 = ["1"]
        vnet_subnet_id        = dependency.vnet.outputs.subnet_ids["AKSSubnet"]
      }

      network_profile         = {
        plugin                = "azure"
        plugin_mode           = "overlay"
        lb_sku                = "standard"
        service_cidr          = "10.22.0.0/24"
        dns_ip                = "10.22.0.4"
      }

      linux_profile           = {
        username              = "aksadmin"
      }

      scope_acr_id            = dependency.acr.outputs.acr_ids["aks"]

      node_pools              = {
        frontpool             = {
          name                = "frontpool"
          vm_size             = "Standard_B2s"
          node_count          = 1
          zones               = ["2"]
          vnet_subnet_id      = dependency.vnet.outputs.subnet_ids["AKSSubnet"]
          mode                = "User"
        }
        backpool              = {
          name                = "backpool"
          vm_size             = "Standard_B2s"
          node_count          = 1
          zones               = ["3"]
          vnet_subnet_id      = dependency.vnet.outputs.subnet_ids["AKSSubnet"]
          mode                = "User"
        }
      }
    }
  }
}
