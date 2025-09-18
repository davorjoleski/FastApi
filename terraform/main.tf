

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



# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "fasttapiacr69418"
  resource_group_name = azurerm_resource_group.fastapi_rg.name
  location            = azurerm_resource_group.fastapi_rg.location
  sku                 = "Basic"

 # admin_enabled = true
 #  tags = {
 #    owner       = "terraform"
 #    environment = "dev"
 #  }
}






#for imagePullSecrets  for pods pull images
# resource "kubernetes_secret" "acr_secret" {
#   metadata {
#     name      = "acr-secret"
#     namespace = "default"
#   }
#
#   type = "kubernetes.io/dockerconfigjson"
#
#   data = {
#     ".dockerconfigjson" = jsonencode({
#       auths = {
#         "${azurerm_container_registry.acr.login_server}" = {
#           username = azurerm_container_registry.acr.admin_username
#           password = azurerm_container_registry.acr.admin_password
#           email    = "example@intertec.io"
#         }
#       }
#     })
#   }
# }

##########################################################
# Secret за Azure Storage Connection String
##########################################################
resource "kubernetes_secret" "azure_storage_secret" {
  metadata {
    name      = "azure-connection-secret"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    connectionString = azurerm_storage_account.fastapistorageacct.primary_connection_string
  }
}
