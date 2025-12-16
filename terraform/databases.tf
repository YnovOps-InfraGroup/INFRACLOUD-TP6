
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
  zone                   = "1"
  administrator_login    = "n8nadmin"
  administrator_password = azurerm_key_vault_secret.pg_password.value
  storage_mb             = 32768
  sku_name               = "B_Standard_B2s"

  delegated_subnet_id           = azurerm_subnet.Subnet2.id
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