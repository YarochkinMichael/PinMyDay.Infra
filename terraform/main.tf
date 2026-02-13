terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-pmd-terraform-we"
    storage_account_name = "sapmdterraformstatewe"
    container_name       = "sc-pmd-terraform-state-we"
    key                  = "dev.tfstate" # change in prod workflow
  }
}

provider "azurerm" {
  features {}
}
