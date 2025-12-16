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
