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
