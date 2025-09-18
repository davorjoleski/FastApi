
# Storage Account
resource "azurerm_storage_account" "fastapistorageacct" {
  name                     = "fastapistorageacct"
  resource_group_name      = azurerm_resource_group.fastapi_rg.name
  location                 = azurerm_resource_group.fastapi_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Blob Container
resource "azurerm_storage_container" "intake" {
  name                  = "intake"
  storage_account_id    = azurerm_storage_account.fastapistorageacct.id
  container_access_type = "private"
}
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.fastapistorageacct.id
  container_access_type = "private"
}