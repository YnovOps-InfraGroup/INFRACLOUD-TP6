resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-n8n-cluster"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  dns_prefix          = "n8n-aks"

  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.10.0.0/16"
    dns_service_ip = "10.10.0.10"
  }

  default_node_pool {
    name           = "default"
    node_count     = 3
    vm_size        = "Standard_D2_v3"
    vnet_subnet_id = azurerm_subnet.Subnet1.id

    temporary_name_for_rotation = "tempnode"
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}