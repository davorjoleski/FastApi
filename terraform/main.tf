resource "azurerm_resource_group" "main" {
  name     = "fastapi-rg"
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "fastapistorageapp"  # уникатно име!
  resource_group_name      = azurerm_resource_group.main.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "intake" {
  name                  = "intake"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_container_registry" "acr" {
  name                = "fastapiacr001"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "fastapi-aks-cluster"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "fastapikube"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  depends_on = [azurerm_container_registry.acr]
}
