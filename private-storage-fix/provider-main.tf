terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.47.0"
    }
  }
  # options for remote backend in Azure storage
  # backend "azurerm" {
  #   resource_group_name  = "xxx"
  #   storage_account_name = "xxx"
  #   container_name       = "xxx"
  #   key                  = "xxx"
  # }
}

# Configure the Azure provider
provider "azurerm" {
  subscription_id = var.azure-subscription-id
  tenant_id       = var.azure-tenant-id
  client_id       = var.azure-client-id
  client_secret   = var.azure-client-secret
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}