# main.tf

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

data "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  resource_group_name = data.azurerm_resource_group.rg.name
}


data "azurerm_subnet" "snet_aks" {
  name                 = "Snet-Aks"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

data "azurerm_subnet" "snet_admin_agic" {
  name                 = "Snet-ADMIN"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

data "azurerm_subnet" "snet_db" {
  name                 = "Snet-DB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}


resource "azurerm_container_registry" "acr" {
  name                = "${var.acr_name_prefix}${random_integer.suffix.result}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true

  identity {
    type = "SystemAssigned"
  }
}

resource "random_integer" "suffix" {
  min = 1000
  max = 9999
}

resource "azurerm_key_vault" "akv" {
  name                       = "akv-n8n-tf-secrets"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete"
    ]
  }
}

resource "azurerm_key_vault_secret" "pg_password" {
  name         = "pg-admin-password"
  key_vault_id = azurerm_key_vault.akv.id
  value        = var.pg_admin_password
}

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
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = data.azurerm_subnet.snet_aks.id # Utilise data
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true
}

resource "azurerm_private_dns_zone" "pg_private_dns" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg_dns_link" {
  name                  = "link-to-vnet1"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pg_private_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_postgresql_flexible_server" "pg" {
  name                   = "pg-n8n-tf-server"
  resource_group_name    = data.azurerm_resource_group.rg.name
  location               = data.azurerm_resource_group.rg.location
  version                = "14"
  administrator_login    = "n8nadmin"
  administrator_password = azurerm_key_vault_secret.pg_password.value
  storage_mb             = 32768
  sku_name               = "B_Standard_B2s"

  delegated_subnet_id           = data.azurerm_subnet.snet_db.id # Utilise data
  public_network_access_enabled = false
  private_dns_zone_id           = azurerm_private_dns_zone.pg_private_dns.id
}

resource "azurerm_postgresql_flexible_server_database" "n8n_db" {
  name      = "n8n_db"
  server_id = azurerm_postgresql_flexible_server.pg.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_redis_cache" "redis" {
  name                = "redis-n8n-tf-cache"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  capacity            = 1
  family              = "C"
  sku_name            = "Basic"
}

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