output "resource_group_id" {
  value = azurerm_resource_group.rg_app.id
}

output "storage_account_names" {
  description = "Noms de tous les Storage Accounts créés."
  value = [
    for s in azurerm_storage_account.dynamic_storages : s.name
  ]
}