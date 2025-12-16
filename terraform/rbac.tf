# Attribution du rôle AcrPull à l'AKS pour tirer les images de l'ACR
# Cette attribution permet au kubelet d'AKS de tirer les images depuis l'ACR
# NOTE: Nécessite les permissions "User Access Administrator" ou "Owner"
# Si vous avez une erreur d'authentification, contactez votre administrateur Azure
# ou utilisez une alternative avec les credentials d'admin ACR dans un imagePullSecret
resource "azurerm_role_assignment" "aks_acr_pull" {
  count                = 1 # Set to 0 if you don't have permissions
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_container_registry.acr]
}
