# Définition du Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Appel du module Network
module "network" {
  source = "../modules/network"

  # On utilise le Resource Group qui a été créé par le module app_stack ?
  # Non, le module app_stack crée le RG en interne.
  # Pour simplifier, nous allons laisser le module network utiliser le MEME groupe de ressources.
  # Mais attention : le module network a besoin du NOM du resource group.

  # Astuce : On récupère l'ID du RG depuis la sortie du module app_stack
  # On va devoir "extraire" le nom, ou modifier app_static pour sortir le nom aussi.
  # SIMPLIFICATION POUR LE TP : Passons le nom construit manuellement ou modifions app_static outputs.

  # Pour éviter les dépendances circulaires complexes maintenant, passons le nom reconstruit :
  resource_group_name = "rg-${var.app_name}-${var.environment}-${var.location}"

  location            = var.location
  tags                = var.mandatory_tags
  vnet_cidr           = var.vnet_cidr
  ingress_rules       = var.ingress_rules

  # On s'assure que le RG existe avant de créer le réseau (dépendance implicite via app_stack)
  #depends_on = [module.app_stack]
}
# env/dev/main.tf

# Ressource existante à importer
resource "azurerm_resource_group" "imported_rg" {
  name     = "rg-manual-import-test"
  location = "switzerlandnorth"

  # On ajoute des tags pour voir si Terraform détecte la différence
  tags     = {
    Source = "Imported"
    Owner  = "Thibaut"
  }
}