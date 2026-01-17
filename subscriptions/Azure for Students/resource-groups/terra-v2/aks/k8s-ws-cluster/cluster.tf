resource "azurerm_kubernetes_cluster" "k8s-ws-cluster" {
  name                        = "k8s-ws-cluster-${var.resource_group_name}"
  resource_group_name         = var.resource_group_name
  location                    = var.location
  dns_prefix                  = var.resource_group_name
  kubernetes_version          = var.kubernetes_version

  #automatic_channel_upgrade = "patch"
  automatic_upgrade_channel   = "patch"
  image_cleaner_interval_hours = 48

  private_cluster_enabled = false
  default_node_pool {
    name                        = "system"
    node_count                  = 1
    vm_size                     = var.instance_type
    vnet_subnet_id              = data.azurerm_subnet.cluster_subnet.id
    temporary_name_for_rotation = "systemtemp"
    orchestrator_version        = var.kubernetes_version
    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0

    }
 }
  identity { 
    type = "SystemAssigned"
 }

}