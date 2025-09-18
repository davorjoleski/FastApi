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