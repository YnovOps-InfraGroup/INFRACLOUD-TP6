# modules/app-static/main.tf

# --- Logique de Nommage ---
locals {
  storage_account_name = "sa${var.app_name}${var.environment}art" 
  resource_group_name = "rg-${var.app_name}-${var.environment}-${var.location}"
}

# --- 1. Resource Group ---
resource "azurerm_resource_group" "rg_app" {
  name     = local.resource_group_name
  location = var.location
  tags     = var.tags
}

# --- 2. Storage Account (Artefact, utilise for_each) ---
resource "azurerm_storage_account" "dynamic_storages" {
  for_each = var.storage_configs

  name                     = "sa${var.app_name}${var.environment}${each.key}"
  resource_group_name      = azurerm_resource_group.rg_app.name
  location                 = azurerm_resource_group.rg_app.location

  account_tier             = "Standard"
  account_replication_type = each.value.replication_type

  # CORRECTION ICI : "kind" devient "account_kind"
  account_kind             = each.value.kind
  
  tags                     = var.tags
}

# --- 3. Conteneur Blob ---
resource "azurerm_storage_container" "artifacts_container" {
  name                  = "artifacts"
  # Nous le lions au Storage Account avec la clé "primary"
  storage_account_name  = azurerm_storage_account.dynamic_storages["primary"].name 
  container_access_type = "private"
}