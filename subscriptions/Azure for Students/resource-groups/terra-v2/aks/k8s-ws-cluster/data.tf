data "azurerm_virtual_network" "cluster_vnet" {
  name                = "cluster-vnet-${var.resource_group_name}"
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "cluster_subnet" {
  name                 = "cluster-subnet-${var.resource_group_name}"
  virtual_network_name = "cluster-vnet-${var.resource_group_name}"
  resource_group_name  = var.resource_group_name
}