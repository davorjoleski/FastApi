# Create the Azure Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    environment = "production"
  }
}

# Generate a random string suffix for unique naming
resource "random_string" "suffix" {
  length  = var.suffix_length
  special = false
  upper   = false
}

# Create an Azure Storage Account for blob storage
resource "azurerm_storage_account" "sa" {
  name                     = lower("st${random_string.suffix.result}")  # must be lowercase, unique
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  # Best practice: disable public access (true by default)
  allow_nested_items_to_be_public = false
  tags = {
    environment = "production"
  }
}

# Create a container named "intake" for document uploads
resource "azurerm_storage_container" "intake_container" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Create an Azure Container Registry for Docker images
resource "azurerm_container_registry" "acr" {
  name                = lower("${var.acr_name}${random_string.suffix.result}")  # unique name with suffix
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false  # we use Azure AD auth, so disable the admin user
  tags = {
    environment = "production"
  }
}

# Create an Azure Kubernetes Service (AKS) cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_DS2_v2"
  }

  # Use system-assigned managed identity for the cluster
  identity {
    type = "SystemAssigned"
  }

  # Enable RBAC for the cluster
  role_based_access_control {
    enabled = true
  }

  # Kubernetes version can be specified if needed (default is latest available)
  # kubernetes_version = "1.24.0"
}

# Grant AKS permission to pull images from the ACR (assign AcrPull role)
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
  # Ensures Terraform doesn't drop this role assignment on refresh
  skip_service_principal_aad_check = true
}
