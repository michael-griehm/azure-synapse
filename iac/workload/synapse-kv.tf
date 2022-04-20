data "azurerm_key_vault" "synapse_vault" {
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = "cryptoanalyticssynapse"
}

resource "azurerm_key_vault_access_policy" "synapse_workspace" {
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_synapse_workspace.synapse.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_key_vault_secret" "snowflake_url" {
  name         = "snowflake-url"
  value        = var.snowflake_url
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "snowflake_username" {
  name         = "snowflake-username"
  value        = var.snowflake_username
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
  tags         = var.tags
}

resource "azurerm_key_vault_secret" "snowflake_password" {
  name         = "snowflake-password"
  value        = var.snowflake_password
  key_vault_id = data.azurerm_key_vault.synapse_vault.id
  tags         = var.tags
}