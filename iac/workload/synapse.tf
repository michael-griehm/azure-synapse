data "azuread_user" "synapse_admin_user_account" {
  user_principal_name = var.synapse_admin_principal_name
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "cryptoanalyticssynapse"
  resource_group_name                  = data.azurerm_resource_group.rg.name
  location                             = data.azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_workspace.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = random_password.password.result
  tags                                 = var.tags

  aad_admin {
    login     = "AzureAD Admin"
    object_id = data.azuread_user.synapse_admin_user_account.object_id
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

resource "azurerm_key_vault_secret" "sql_administrator_login" {
  name         = azurerm_synapse_workspace.synapse.sql_administrator_login
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
}

resource "azurerm_synapse_sql_pool" "crypto_analytics" {
  name                 = "crypto_analytics"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  tags                 = var.tags
}

resource "azurerm_synapse_firewall_rule" "allow_all" {
  name                 = "allow-all"
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