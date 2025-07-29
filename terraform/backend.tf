terraform {
  backend "azurerm" {
    resource_group_name   = "terraform_boot"         # RG containing the state storage account
    storage_account_name  = "terraformsstorage"     # Name of the storage account for state
    container_name        = "intake"         # Blob container for state
    key                   = "terraform.tfstate"  # State file name
    use_azuread_auth      = true              # Authenticate using Azure AD (ARM_ env vars)
    # (ARM_TENANT_ID and other ARM_ vars will be provided by CI environment)
  }
}
