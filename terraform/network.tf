resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "Subnet1" {
  name                 = "Snet-Aks"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "Subnet2" {
  name                 = "Snet-DB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "fs"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "Subnet3" {
  name                 = "Snet-ADMIN"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "Subnet_ALB" {
  name                 = "Snet-ALB"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.4.0/24"]

  delegation {
    name = "delegation-alb"
    service_delegation {
      name    = "Microsoft.ServiceNetworking/trafficControllers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_application_load_balancer" "alb" {
  name                = "AGC-N8N-AKS"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_application_load_balancer_subnet_association" "albsubnet" {
  name                         = "vnet-link"
  application_load_balancer_id = azurerm_application_load_balancer.alb.id
  subnet_id                    = azurerm_subnet.Subnet_ALB.id
}

resource "azurerm_application_load_balancer_frontend" "alb_frontend" {
  name                         = "n8n-frontend"
  application_load_balancer_id = azurerm_application_load_balancer.alb.id

  tags = {
    environment = "DEV"
    application = "n8n"
  }
}