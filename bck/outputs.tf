output "storage_account_names" {
  description = "Noms de tous les Storage Accounts créés."
  value       = module.app_stack.storage_account_names # Référence le output du module enfant
}

output "resource_group_id" {
  description = "ID du Resource Group créé."
  value       = module.app_stack.resource_group_id
}