provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "fastapi-rg"
  location = "West Europe"
}

resource "azurerm_storage_account" "main" {
  name                     = "fastapistorageacct"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "intake" {
  name                  = "intake"
  storage_account_id  = azurerm_storage_account.main.name
  container_access_type = "private"
}

resource "azurerm_container_registry" "acr" {
  name                = "fastapiacr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "fastapi-aks-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "fastapiaks"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }
}
