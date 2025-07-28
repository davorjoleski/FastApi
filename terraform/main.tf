terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.96.0"
    }
  }
  backend "local" {} # Може и Azure backend, но локално е доволно за сега
}

provider "azurerm" {
  features {}

    skip_provider_registration = true

}

# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "fastapi-rg"
  location = "West Europe"
}

# 2. Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "fastapireg1234" # мора да биде globally unique
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# 3. Azure Kubernetes Service (AKS)
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "fastapi-aks-cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "fastapi"

  default_node_pool {
    name       = "default"
    node_count = 2
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }

  # Attach ACR to AKS
  depends_on = [azurerm_container_registry.acr]
}

# 4. Attach ACR to AKS (needed manually)
resource "azurerm_role_assignment" "acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.aks.identity.principal_id
  role_definition_name            = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
}
