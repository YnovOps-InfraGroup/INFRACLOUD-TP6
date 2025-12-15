terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.56.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "cd3fa1ba-5253-4f92-8571-9b1fde759c19"
  features {}

}