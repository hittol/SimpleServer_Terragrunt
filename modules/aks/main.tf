# ===================================================================
# Load Tenant ID
# ===================================================================

data "azurerm_client_config" "current" {}

# ===================================================================
# Create SSH Key
# ===================================================================

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = var.key_path
  file_permission = "0600"
}

resource "azurerm_ssh_public_key" "vm_ssh_key" {
  name                = "aks-admin-key"
  resource_group_name = var.managed_rg_name
  location            = var.location
  public_key          = tls_private_key.ssh_key.public_key_openssh
}

# ===================================================================
# ManagedIdentity Create
# ===================================================================

resource "azurerm_user_assigned_identity" "aks_ManagedID" {
  for_each              = var.aks_setting 

  name                  = "UAMI-${each.value.aks_name}"
  location              = var.location
  resource_group_name   = each.value.managed_rg_name
}

resource "azurerm_role_assignment" "dns_role_assign" {
  for_each              = var.aks_setting

  scope                 = each.value.scope_dns_id
  role_definition_name  = "Private DNS Zone Contributor"
  principal_id          = azurerm_user_assigned_identity.aks_ManagedID[each.key].principal_id
}

resource "azurerm_role_assignment" "network_role_assign" {
  for_each              = var.aks_setting

  scope                 = each.value.scope_vnet_id
  role_definition_name  = "Network Contributor"
  principal_id          = azurerm_user_assigned_identity.aks_ManagedID[each.key].principal_id
  depends_on            = [azurerm_role_assignment.dns_role_assign]
}

# ===================================================================
# Create Front aks cluster
# ===================================================================

resource "azurerm_kubernetes_cluster" "aks" {
  for_each                            = var.aks_setting

  name                                = each.value.aks_name
  resource_group_name                 = each.value.rg_name
  node_resource_group                 = each.value.node_rg_name
  location                            = var.location
  sku_tier                            = each.value.aks_tier

  oidc_issuer_enabled                 = each.value.oidc_enabled
  workload_identity_enabled           = each.value.workload_enabled

  private_cluster_enabled             = each.value.private_cluster_enabled
  private_cluster_public_fqdn_enabled = each.value.public_fqdn_enabled
  private_dns_zone_id                 = each.value.private_dns_zone_id
  dns_prefix                          = each.value.dns_prefix
  azure_policy_enabled                = each.value.policy_enabled

  default_node_pool {
    name            = each.value.default_node.name
    node_count      = each.value.default_node.node_count
    vm_size         = each.value.default_node.vm_size
    zones           = each.value.default_node.zones
    vnet_subnet_id  = each.value.default_node.vnet_subnet_id
  }

  network_profile {
    network_plugin      = each.value.network_profile.plugin
    network_plugin_mode = each.value.network_profile.plugin_mode
    network_policy      = each.value.network_profile.policy
    load_balancer_sku   = each.value.network_profile.lb_sku
    service_cidr        = each.value.network_profile.service_cidr
    dns_service_ip      = each.value.network_profile.dns_ip
    outbound_type       = each.value.network_profile.outbound_type
  } 

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled  = true
    tenant_id           = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type                = "UserAssigned"
    identity_ids        = [azurerm_user_assigned_identity.aks_ManagedID[each.key].id]
  }

  linux_profile {
    admin_username      = "useradmin"
    ssh_key {
      key_data          = azurerm_ssh_public_key.vm_ssh_key.public_key
    }
  }

  depends_on = [ 
    azurerm_role_assignment.network_role_assign,
    azurerm_role_assignment.dns_role_assign
  ]
}

resource "azurerm_role_assignment" "aks_acr_pull_role_assign" {
  for_each              = var.aks_setting

  scope                 = each.value.scope_acr_id
  role_definition_name  = "AcrPull"
  principal_id          = azurerm_kubernetes_cluster.aks[each.key].kubelet_identity[0].object_id
}


# ===================================================================
# Create Node Pool
# ===================================================================

locals {
  aks_node_pools = merge([
    for aks_key, aks in var.aks_setting : {
      for np_key, np in aks.node_pools :
      "${aks_key}.${np_key}" => {
        aks_key        = aks_key
        name           = np.name
        vm_size        = np.vm_size
        node_count     = np.node_count
        zones          = np.zones
        vnet_subnet_id = np.vnet_subnet_id
        mode           = np.mode
        node_labels    = np.node_labels
        node_taints    = np.node_taints
      }
    }
  ]...)
}

resource "azurerm_kubernetes_cluster_node_pool" "nodepool" {
  for_each              = local.aks_node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks[each.value.aks_key].id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count
  zones                 = each.value.zones
  mode                  = each.value.mode
  vnet_subnet_id        = each.value.vnet_subnet_id
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints
}