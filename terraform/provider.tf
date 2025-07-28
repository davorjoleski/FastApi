# Configure Terraform to use the latest AzureRM (v4.x) and random providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.37.0"  # Use latest AzureRM provider (v4.x series)
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"    # Used for generating unique name suffixes
    }
  }
}

# Azure Resource Manager Provider
provider "azurerm" {
  features {}
    client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret
  tenant_id       = var.arm_tenant_id
  subscription_id = var.arm_subscription_id
  # Required block for AzureRM provider (no custom features in this setup)
}

# (Optional) Pin Terraform CLI version if needed, or rely on workflow to set version
