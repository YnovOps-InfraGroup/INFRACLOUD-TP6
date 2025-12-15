variable "rg" {
  type    = string
  default = "RG-N8N-AKS"
}

data "azurerm_resource_group" "rg" {
  name = var.rg

}
