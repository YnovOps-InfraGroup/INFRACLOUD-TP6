provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
}

# Création du namespace n8n
resource "kubernetes_namespace" "n8n" {
  metadata {
    name = "n8n"
    labels = {
      "app.kubernetes.io/name"       = "n8n"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks]
}

# Créer un imagePullSecret pour l'ACR dans le namespace n8n
resource "kubernetes_secret" "acr_credentials" {
  metadata {
    name      = "acr-secret"
    namespace = kubernetes_namespace.n8n.metadata[0].name
  }

  type = "kubernetes.io/dockercfg"

  data = {
    ".dockercfg" = jsonencode({
      (azurerm_container_registry.acr.login_server) = {
        username = azurerm_container_registry.acr.admin_username
        password = azurerm_container_registry.acr.admin_password
        email    = "n8n@example.com"
        auth     = base64encode("${azurerm_container_registry.acr.admin_username}:${azurerm_container_registry.acr.admin_password}")
      }
    })
  }

  depends_on = [kubernetes_namespace.n8n]
}

