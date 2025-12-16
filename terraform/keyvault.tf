# keyvault.tf

resource "azurerm_key_vault" "akv" {
  name                       = "akv-n8n-tf-secrets"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
]
  }
  lifecycle {
    # 💥 SOLUTION : Ignorer tous les changements APRES la création
    # Si d'autres politiques sont ajoutées manuellement ou par d'autres scripts,
    # Terraform ignorera les changements sur la liste complète des politiques.
    ignore_changes = [
      access_policy
    ]
  }
}

resource "azurerm_key_vault_secret" "pg_password" {
  name         = "pg-admin-password"
  key_vault_id = azurerm_key_vault.akv.id
  value        = var.pg_admin_password
}