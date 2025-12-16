<<<<<<< HEAD

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_client_config" "current" {}

=======
variable "rg" {
  type    = string
  default = "RG-N8N-AKS"
}

data "azurerm_resource_group" "rg" {
  name = var.rg

}
>>>>>>> 73079a2398e45efcc9631ab18cfaf17e59563c4b
