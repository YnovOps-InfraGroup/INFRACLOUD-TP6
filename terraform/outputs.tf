
# ========================================
# OUTPUTS POUR DEBUG ET CONNEXION
# ========================================

# --- Container Registry (ACR) ---
output "acr_login_server" {
  description = "URL du serveur ACR pour docker login"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_admin_username" {
  description = "Username admin ACR"
  value       = azurerm_container_registry.acr.admin_username
  sensitive   = true
}

output "acr_admin_password" {
  description = "Password admin ACR"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "acr_id" {
  description = "ID de la ressource ACR"
  value       = azurerm_container_registry.acr.id
}

# --- AKS Cluster ---
output "aks_cluster_name" {
  description = "Nom du cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "ID du cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_fqdn" {
  description = "FQDN du cluster AKS"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "kube_config" {
  description = "Kubeconfig pour se connecter au cluster AKS"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
}

output "aks_kubelet_identity" {
  description = "Identity utilisée par kubelet pour pull images"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# --- Database PostgreSQL ---
output "postgresql_server_name" {
  description = "Nom du serveur PostgreSQL"
  value       = azurerm_postgresql_flexible_server.pg.name
}

output "postgresql_fqdn" {
  description = "FQDN du serveur PostgreSQL"
  value       = azurerm_postgresql_flexible_server.pg.fqdn
}

output "postgresql_database_name" {
  description = "Nom de la base de données N8N"
  value       = azurerm_postgresql_flexible_server_database.n8n_db.name
}

output "postgresql_admin_username" {
  description = "Username admin PostgreSQL"
  value       = azurerm_postgresql_flexible_server.pg.administrator_login
  sensitive   = true
}

# --- Redis Cache ---
output "redis_hostname" {
  description = "Hostname Redis pour connexion"
  value       = azurerm_redis_cache.redis.hostname
}

output "redis_port" {
  description = "Port Redis (6380 pour SSL)"
  value       = azurerm_redis_cache.redis.ssl_port
}

output "redis_primary_key" {
  description = "Clé primaire Redis"
  sensitive   = true
  value       = azurerm_redis_cache.redis.primary_access_key
}

output "redis_connection_string" {
  description = "String de connexion Redis complet"
  sensitive   = true
  value       = "${azurerm_redis_cache.redis.hostname}:${azurerm_redis_cache.redis.ssl_port},password=${azurerm_redis_cache.redis.primary_access_key},ssl=True,abortConnect=False"
}

# --- Application Load Balancer ---
output "alb_id" {
  description = "ID de l'Application Load Balancer"
  value       = azurerm_application_load_balancer.alb.id
}

output "alb_name" {
  description = "Nom de l'Application Load Balancer"
  value       = azurerm_application_load_balancer.alb.name
}

output "alb_frontend_id" {
  description = "ID du frontend ALB"
  value       = azurerm_application_load_balancer_frontend.alb_frontend.id
}

output "alb_frontend_fqdn" {
  description = "FQDN du frontend ALB (si disponible)"
  value       = try(azurerm_application_load_balancer_frontend.alb_frontend.fully_qualified_domain_name, "Non configuré - Configurer un domaine custom")
}

# --- Key Vault ---
output "keyvault_name" {
  description = "Nom du Key Vault"
  value       = azurerm_key_vault.akv.name
}

output "keyvault_uri" {
  description = "URI du Key Vault"
  value       = azurerm_key_vault.akv.vault_uri
}

# --- Network ---
output "vnet_id" {
  description = "ID du Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "subnet_aks_id" {
  description = "ID du subnet AKS"
  value       = azurerm_subnet.Subnet1.id
}

output "subnet_db_id" {
  description = "ID du subnet Database"
  value       = azurerm_subnet.Subnet2.id
}

output "subnet_alb_id" {
  description = "ID du subnet ALB"
  value       = azurerm_subnet.Subnet_ALB.id
}

# --- Resource Group ---
output "resource_group_name" {
  description = "Nom du Resource Group"
  value       = data.azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Localisation du Resource Group"
  value       = data.azurerm_resource_group.rg.location
}

# ========================================
# COMMANDES UTILES POUR DEBUG
# ========================================

output "debug_commands" {
  description = "Commandes utiles pour déboguer l'infrastructure"
  value       = <<-EOT
  
  ## Connexion AKS
  az aks get-credentials --resource-group ${data.azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name}
  kubectl get nodes
  kubectl get pods -n n8n
  
  ## Connexion ACR
  az acr login --name ${azurerm_container_registry.acr.name}
  docker login ${azurerm_container_registry.acr.login_server}
  
  ## Tester PostgreSQL
  psql "host=${azurerm_postgresql_flexible_server.pg.fqdn} port=5432 dbname=${azurerm_postgresql_flexible_server_database.n8n_db.name} user=${azurerm_postgresql_flexible_server.pg.administrator_login} sslmode=require"
  
  ## Tester Redis
  redis-cli -h ${azurerm_redis_cache.redis.hostname} -p ${azurerm_redis_cache.redis.ssl_port} -a [PRIMARY_KEY] --tls
  
  ## Vérifier l'ALB
  az network application-gateway for-containers show --name ${azurerm_application_load_balancer.alb.name} --resource-group ${data.azurerm_resource_group.rg.name}
  
  EOT
}