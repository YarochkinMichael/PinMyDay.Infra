terraform {
  backend "azurerm" {
    resource_group_name  = "rg-pmd-terraform-we"
    storage_account_name = "sapmdterraformstatewe"
    container_name       = "sc-pmd-terraform-state-we"
    # key is provided at init time:
    # -backend-config="key=dev.tfstate" or prod.tfstate
  }
}

provider "azurerm" {
  features {}
}
