terraform {
  backend "azurerm" {
    resource_group_name  = "unirdemos"
    storage_account_name = "tfstate87936"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"
  }
}