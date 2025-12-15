terraform {
  backend "azurerm" {
    resource_group_name  = "RG-N8N-AKS"
    storage_account_name = "stoynovgroup"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}