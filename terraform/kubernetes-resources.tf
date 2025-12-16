# ========================================
# RESSOURCES KUBERNETES GÉRÉES PAR TERRAFORM
# ========================================
# Ce fichier crée les ressources K8s avec les valeurs dynamiques
# issues des autres ressources Terraform

# ConfigMap N8N avec valeurs dynamiques
resource "kubernetes_config_map" "n8n_config" {
  metadata {
    name      = "n8n-config-vars"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  data = {
    # Mode d'exécution
    EXECUTIONS_MODE = "queue"

    # Configuration PostgreSQL (valeurs dynamiques depuis Terraform)
    DB_TYPE     = "postgres"
    DB_HOST     = azurerm_postgresql_flexible_server.pg.fqdn
    DB_DATABASE = azurerm_postgresql_flexible_server_database.n8n_db.name
    DB_PORT     = "5432"

    # Configuration Redis pour la queue (valeurs dynamiques)
    QUEUE_BULL_REDIS_HOST = azurerm_redis_cache.redis.hostname
    QUEUE_BULL_REDIS_PORT = tostring(azurerm_redis_cache.redis.ssl_port)
    QUEUE_BULL_REDIS_TLS  = "true"

    # Configuration N8N (l'URL externe sera mise à jour après création de l'ALB)
    N8N_HOST               = "http://${azurerm_application_load_balancer_frontend.alb_frontend.fully_qualified_domain_name}"
    N8N_INTERNAL_HOST      = "http://n8n-service.${kubernetes_namespace.n8n.metadata[0].name}.svc.cluster.local:5678"
    N8N_WORKER_CONCURRENCY = "5"

    # Timezone
    GENERIC_TIMEZONE = "Europe/Paris"
    TZ               = "Europe/Paris"
  }

  depends_on = [
    kubernetes_namespace.n8n,
    azurerm_postgresql_flexible_server.pg,
    azurerm_redis_cache.redis,
    azurerm_application_load_balancer_frontend.alb_frontend
  ]
}

# Secret N8N avec valeurs sensibles depuis Terraform
resource "kubernetes_secret" "n8n_secrets" {
  metadata {
    name      = "n8n-sensitive-secrets"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  type = "Opaque"

  data = {
    # Credentials PostgreSQL
    DB_USER     = base64encode(azurerm_postgresql_flexible_server.pg.administrator_login)
    DB_PASSWORD = base64encode(azurerm_key_vault_secret.pg_password.value)

    # Credentials Redis
    QUEUE_BULL_REDIS_PASSWORD = base64encode(azurerm_redis_cache.redis.primary_access_key)

    # Clé de chiffrement N8N (depuis variable ou générée si vide)
    N8N_ENCRYPTION_KEY = base64encode(var.n8n_encryption_key != "" ? var.n8n_encryption_key : random_password.n8n_encryption_key.result)
  }

  depends_on = [
    kubernetes_namespace.n8n,
    azurerm_postgresql_flexible_server.pg,
    azurerm_redis_cache.redis,
    azurerm_key_vault_secret.pg_password
  ]
}

# Génération d'une clé de chiffrement aléatoire pour N8N (si non fournie)
resource "random_password" "n8n_encryption_key" {
  length  = 32
  special = true

  # Cette ressource ne sera utilisée que si var.n8n_encryption_key est vide
  lifecycle {
    ignore_changes = all # Évite de regénérer la clé à chaque apply
  }
}

# Note: Les Deployments et Services restent en YAML car ils ne changent pas
# et sont plus faciles à maintenir en YAML pur.
# Seules les configurations dynamiques (ConfigMap/Secret) sont gérées par Terraform.
