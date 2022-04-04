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

resource "azurerm_key_vault_secret" "stored_secret" {
  name         = azurerm_synapse_workspace.synapse.sql_administrator_login
  value        = random_password.password.result
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
}

resource "azurerm_synapse_sql_pool" "example" {
  name                 = "crypto_gold"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  data_encrypted       = true
  tags                 = var.tags
}