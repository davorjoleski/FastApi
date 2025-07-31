terraform {
  backend "azurerm" {
    resource_group_name   = "fastapi-rg"
    storage_account_name = "fastapistorageacct"
    container_name       = "intake"
    key                  = "terraform.tfstate"
  }
}
