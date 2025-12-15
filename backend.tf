terraform {
  backend "azurerm" {
    # ⚠️ REMPLACEZ LES VALEURS PAR VOS NOMS AZURE RÉELS
    resource_group_name  = "rg-tf-backends-prod-ch"
    storage_account_name = "tfst11271053" # Ex: tfst11271053
    container_name       = "tfstate"
    key                  = "env/dev/terraform.tfstate" # Clé unique pour l'environnement dev
  }
}