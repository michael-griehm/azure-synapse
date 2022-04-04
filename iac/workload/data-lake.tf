data "azurerm_storage_account" "adls" {
  name                = "cryptoanalyticslake"
  resource_group_name = "adls2-demo-eastus2"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_workspace" {
  name               = "synapse-workspace"
  storage_account_id = data.azurerm_storage_account.adls.id
}
