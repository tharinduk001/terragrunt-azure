resource "azurerm_virtual_network" "vnet" {
  name                = "cluster-vnet-${var.resource_group_name}"
  address_space       = ["10.3.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name
}