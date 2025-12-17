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
    DB_TYPE                               = "postgresdb"
    DB_POSTGRESDB_HOST                    = azurerm_postgresql_flexible_server.pg.fqdn
    DB_POSTGRESDB_DATABASE                = azurerm_postgresql_flexible_server_database.n8n_db.name
    DB_POSTGRESDB_PORT                    = "5432"
    DB_POSTGRESDB_SSL                     = "true"
    DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED = "false"
    # Anciennes variables pour compatibilité
    DB_HOST                    = azurerm_postgresql_flexible_server.pg.fqdn
    DB_DATABASE                = azurerm_postgresql_flexible_server_database.n8n_db.name
    DB_PORT                    = "5432"
    DB_SSL                     = "true"
    DB_SSL_REJECT_UNAUTHORIZED = "false"

    # Désactive explicitement sqlite
    DB_SQLITE_VACUUM_ON_STARTUP = "false"

    # Configuration Redis pour la queue (valeurs dynamiques)
    QUEUE_BULL_REDIS_HOST = azurerm_redis_cache.redis.hostname
    QUEUE_BULL_REDIS_PORT = tostring(azurerm_redis_cache.redis.ssl_port)
    QUEUE_BULL_REDIS_TLS  = "true"

    # Configuration N8N
    # Utilise l'IP publique du LoadBalancer directement (l'ALB nécessiterait un HTTPRoute)
    N8N_HOST               = "4.178.17.26"
    N8N_PROTOCOL           = "http"
    N8N_SECURE_COOKIE      = "false" # Désactivé pour dev-test (HTTP sans SSL)
    N8N_INTERNAL_HOST      = "http://n8n-service.${kubernetes_namespace.n8n.metadata[0].name}.svc.cluster.local:5678"
    N8N_WORKER_CONCURRENCY = "5"

    # Offload manuel executions vers workers (recommandé)
    OFFLOAD_MANUAL_EXECUTIONS_TO_WORKERS = "true"

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
    # Credentials PostgreSQL (Kubernetes décode automatiquement base64)
    DB_POSTGRESDB_USER     = azurerm_postgresql_flexible_server.pg.administrator_login
    DB_POSTGRESDB_PASSWORD = azurerm_key_vault_secret.pg_password.value
    # Anciennes variables pour compatibilité
    DB_USER     = azurerm_postgresql_flexible_server.pg.administrator_login
    DB_PASSWORD = azurerm_key_vault_secret.pg_password.value

    # Credentials Redis (Kubernetes décode automatiquement base64)
    QUEUE_BULL_REDIS_PASSWORD = azurerm_redis_cache.redis.primary_access_key

    # Clé de chiffrement N8N (depuis variable ou générée si vide)
    N8N_ENCRYPTION_KEY = var.n8n_encryption_key != "" ? var.n8n_encryption_key : random_password.n8n_encryption_key.result
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
