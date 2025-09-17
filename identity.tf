locals {
  vnet_name = var.global_config.global.spoke.network.virtual_network_name
  vnet_resource_group_name = var.global_config.global.spoke.network.virtual_network_resource_group_name
}
resource "azurerm_user_assigned_identity" "kubelet_identity" {
  location            = try(local.kubernetes_cluster.location, var.global_config.global.location)
  name                = "${local.kubernetes_cluster_name}-kubeletid"
  resource_group_name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "cluster_identity" {
  location            = try(local.kubernetes_cluster.location, var.global_config.global.location)
  name                = "${local.kubernetes_cluster_name}-clusterid"
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "cluster_kubelet_id" {
  principal_id                     = azurerm_user_assigned_identity.cluster_identity.principal_id
  role_definition_name             = "Managed Identity Operator"
  scope                            = azurerm_user_assigned_identity.kubelet_identity.id
  skip_service_principal_aad_check = true
}

data "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${try(local.kubernetes_cluster.location, var.global_config.global.location)}.azmk8s.io"
  resource_group_name = var.global_config.global.privatelink_dns_zones.resource_group_name
  provider            = azurerm.privatelink_dns
}

data "azurerm_virtual_network" "this" {
  name                = local.vnet_name
  resource_group_name = local.vnet_resource_group_name
}

resource "azurerm_role_assignment" "cluster_vnet" { # Required to deploy istio internal load balancer
  principal_id                     = azurerm_user_assigned_identity.cluster_identity.principal_id
  role_definition_name             = "Contributor"
  scope                            = data.azurerm_virtual_network.this.id
  skip_service_principal_aad_check = true
}

# resource "azurerm_role_assignment" "cluster_aks_cluster_dns_zone" {
#   principal_id                     = azurerm_user_assigned_identity.cluster_identity.principal_id
#   role_definition_name             = "Private DNS Zone Contributor"
#   scope                            = data.azurerm_private_dns_zone.aks.id
#   skip_service_principal_aad_check = true
# }