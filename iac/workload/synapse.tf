data "azuread_user" "synapse_admin_user_account" {
  user_principal_name = var.synapse_admin_principal_name
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_storage_account" "synapsedatalake" {
  name                     = "cryptoanalyticssynapse"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_root" {
  name               = "synapse-root"
  storage_account_id = azurerm_storage_account.synapsedatalake.id
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "cryptoanalyticssynapse"
  resource_group_name                  = data.azurerm_resource_group.rg.name
  location                             = data.azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_root.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = random_password.password.result
  managed_resource_group_name          = "${data.azurerm_resource_group.rg.name}-managed"
  # managed_virtual_network_enabled      = true
  # data_exfiltration_protection_enabled = true
  # sql_identity_control_enabled         = true
  tags = var.tags

  aad_admin {
    login     = "AzureAD Admin"
    object_id = data.azuread_user.synapse_admin_user_account.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  sql_aad_admin {
    login     = "SQL AzureAD Admin"
    object_id = data.azuread_user.synapse_admin_user_account.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }

  github_repo {
    account_name    = "michael-griehm"
    branch_name     = "main"
    repository_name = "azure-synapse-workspace"
    root_folder     = "/"
  }
}

resource "azurerm_key_vault_secret" "sql_administrator_login" {
  name         = azurerm_synapse_workspace.synapse.sql_administrator_login
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
}

# resource "azurerm_synapse_sql_pool" "crypto_analytics" {
#   name                 = "cryptosql"
#   synapse_workspace_id = azurerm_synapse_workspace.synapse.id
#   sku_name             = "DW100c"
#   create_mode          = "Default"
#   tags                 = var.tags
# }

resource "azurerm_synapse_spark_pool" "crypto_analytics_spark_pool" {
  name                 = "cryptosprk"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  node_size_family     = "MemoryOptimized"
  node_size            = "Small"
  cache_size           = 100
  tags                 = var.tags
  node_count           = 3

  auto_pause {
    delay_in_minutes = 15
  }
}

resource "azurerm_synapse_firewall_rule" "allow_all" {
  name                 = "allow_all"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

resource "azurerm_synapse_role_assignment" "admin_role_assignment" {
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  role_name            = "Synapse Administrator"
  principal_id         = data.azuread_user.synapse_admin_user_account.object_id

  depends_on = [azurerm_synapse_firewall_rule.allow_all]
}

resource "azurerm_role_assignment" "workspace_to_unconnected_lake_role_assignment" {
  scope                = data.azurerm_storage_account.adls.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
}