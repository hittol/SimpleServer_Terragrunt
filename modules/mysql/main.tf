# ===================================================================
# Load Tenant ID & Client ID & Subscription ID
# ===================================================================

data "azurerm_client_config" "current" {}
data "azuread_user" "admin" {
  user_principal_name = var.mysql_entra_login
}
data "azuread_service_principal" "microsoft_graph" {
  client_id = var.client_id
}

# ===================================================================
# Create UAMI
# ===================================================================

resource "azurerm_user_assigned_identity" "uami" {
  for_each              = var.mysql_setting
  
  name                  = "UAMI-${each.value.sql_name}"
  location              = each.value.location
  resource_group_name   = each.value.managed_rg_name
}

locals {
  required_graph_roles = toset([
    "User.Read.All",
    "GroupMember.Read.All",
    "Application.Read.All"
  ])

  graph_app_roles = {
    for role in data.azuread_service_principal.microsoft_graph.app_roles :
    role.value => role.id
    if contains(local.required_graph_roles, role.value)
  }

  mysql_graph_role_assignments = {
    for assignment in flatten([
      for mysql_key, mysql in var.mysql_setting : [
        for role_name in local.required_graph_roles : {
          key       = "${mysql_key}.${role_name}"
          mysql_key = mysql_key
          role_name = role_name
        }
      ]
    ]) :
    assignment.key => assignment
  }
}



# ===================================================================
# Create MySQL Server
# ===================================================================

resource "azurerm_mysql_flexible_server" "mysql" {
  for_each                     = var.mysql_setting

  name                         = each.value.sql_name
  location                     = each.value.location
  resource_group_name          = each.value.sql_rg_name
  administrator_login          = each.value.mysql_login
  administrator_password       = each.value.mysql_passwd
  backup_retention_days        = each.value.backup_day
  delegated_subnet_id          = each.value.dbsubnet_id
  geo_redundant_backup_enabled = each.value.backup_grs
  private_dns_zone_id          = each.value.dns_zone_id
  sku_name                     = each.value.mysql_sku
  version                      = each.value.mysql_version

  dynamic "high_availability" {
    for_each = each.value.high_availability != null ? [each.value.high_availability] : []
    content {
        mode                      = high_availability.value.mode
        standby_availability_zone = high_availability.value.standby_availability_zone
    }
  }

  storage {
    size_gb      = each.value.storage.mysql_gbsize
  }

  identity {
    type         = each.value.identity.type
    identity_ids = [azurerm_user_assigned_identity.uami[each.key].id]
  }
}

# ===================================================================
# Assign RBAC
# ===================================================================

resource "azuread_app_role_assignment" "mysql_graph" {
  for_each              = local.mysql_graph_role_assignments

  principal_object_id   = azurerm_user_assigned_identity.uami[each.value.mysql_key].principal_id
  resource_object_id    = data.azuread_service_principal.microsoft_graph.object_id

  app_role_id           = local.graph_app_roles[each.value.role_name]
}

# ===================================================================
# Entra Authentication
# ===================================================================

resource "azurerm_mysql_flexible_server_active_directory_administrator" "ad_admin" {
  for_each    = var.mysql_setting

  server_id   = azurerm_mysql_flexible_server.mysql[each.key].id
  identity_id = azurerm_user_assigned_identity.uami[each.key].id
  login       = var.mysql_entra_login
  object_id   = data.azuread_user.admin.object_id
  tenant_id   = data.azurerm_client_config.current.tenant_id

  depends_on = [azuread_app_role_assignment.mysql_graph]
}

resource "azurerm_mysql_flexible_server_configuration" "server_config" {
  for_each            = var.mysql_setting

  name                = "aad_auth_only"
  resource_group_name = each.value.sql_rg_name
  server_name         = azurerm_mysql_flexible_server.mysql[each.key].name
  value               = "ON"

  depends_on = [azurerm_mysql_flexible_server_active_directory_administrator.ad_admin]
}