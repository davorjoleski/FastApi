# # Defines remote backend for storing Terraform state (optional if local)
# # Uncomment and configure if using Azure Storage backend
# terraform {
#   backend "azurerm" {
#     resource_group_name   = "fastapi-rg"
#     storage_account_name = "fastapistorageacct"
#     container_name       = "tfstate"
#     key                  = "terraform.tfstate"
#   }
# }
