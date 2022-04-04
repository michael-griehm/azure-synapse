data "azurerm_key_vault" "synapse_vault" {
  resource_group_name = data.azurerm_resource_group.rg.name
  name                = "cryptoanalyticssynapse"
}
