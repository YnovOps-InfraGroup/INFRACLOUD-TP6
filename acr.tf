
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