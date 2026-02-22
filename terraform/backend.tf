# Backend configuration for remote state
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "tfstatedevops2024"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
