
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
output "kube_config" {
  sensitive = true
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
}
output "redis_primary_key" {
  sensitive = true
  value     = azurerm_redis_cache.redis.primary_access_key
}