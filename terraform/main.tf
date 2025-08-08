provider "azurerm" {
  features {}


  client_id       = var.client_id
  client_secret   = var.client_secret
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}



# Random suffix to avoid name conflicts
resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}
# Resource Group
resource "azurerm_resource_group" "fastapi_rg" {
  name     = "fastapi-rg"
  location = "West Europe"
}

# Virtual Network
resource "azurerm_virtual_network" "fastapi_vnet" {
  name                = "fastapi-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.fastapi_rg.location
  resource_group_name = azurerm_resource_group.fastapi_rg.name
}

# Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.fastapi_rg.name
  virtual_network_name = azurerm_virtual_network.fastapi_vnet.name
  address_prefixes     = ["10.0.1.0/24"]


}

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
# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "fasttapiacr69418"
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  location            = azurerm_resource_group.fastapi_rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Kubernetes Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "fastapi-aks-cluster"
  location            = azurerm_resource_group.fastapi_rg.location
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  dns_prefix          = "fastapiaks"

  default_node_pool {
    name                = "default"
    node_count          = 1
    vm_size             = "Standard_DS2_v2"
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip     = "10.0.2.10"
    service_cidr       = "10.0.2.0/24"
  }

  depends_on = [azurerm_subnet.aks_subnet]
}

# Give AKS permission to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
