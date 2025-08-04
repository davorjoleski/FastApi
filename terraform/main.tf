provider "azurerm" {
  features {}

} #provider.tf or versions.tf this can be set

resource "azurerm_resource_group" "fastapi-rg" {
  name     = "fastapi-rg"
  location = "West Europe"
}


resource "azurerm_storage_account" "fastapistorageacct" {
  name                     = "fastapistorageacct"
  resource_group_name      = azurerm_resource_group.fastapi-rg.name
  location                 = azurerm_resource_group.fastapi-rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}


resource "azurerm_storage_container" "intake" {
  name                  = "intake"
  storage_account_id  = azurerm_storage_account.fastapistorageacct.id
  container_access_type = "private"
}
resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}
resource "azurerm_container_registry" "acr" {
  name                = "fasttapiacr69418"
  resource_group_name = azurerm_resource_group.fastapi-rg.name
  location            = azurerm_resource_group.fastapi-rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "fastapi-aks-cluster"
  location            = azurerm_resource_group.fastapi-rg.location
  resource_group_name = azurerm_resource_group.fastapi-rg.name
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
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity.principal_id
}


