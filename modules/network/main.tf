# 1. Réseau Virtuel (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-main"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# 2. Sous-réseau (Subnet)
resource "azurerm_subnet" "public" {
  name                 = "subnet-public"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, 1)] # Ex: 10.0.1.0/24
}

# 3. Groupe de Sécurité (NSG) avec Bloc Dynamique
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-main"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Génération dynamique des règles (Étape 6)
  dynamic "security_rule" {
    for_each = var.ingress_rules
    content {
      name                       = "allow-port-${security_rule.value.port}"
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = tostring(security_rule.value.port)
      source_address_prefixes    = security_rule.value.cidr_blocks
      destination_address_prefix = "*"
    }
  }
}