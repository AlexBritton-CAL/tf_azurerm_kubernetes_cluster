data "azurerm_container_registry" "this" {
  count               = local.acr_connected
  name                = try(var.config.container_registry.name, null)
  resource_group_name = try(var.config.container_registry.resource_group_name, null)
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = local.acr_connected
  scope                = data.azurerm_container_registry.this[count.index].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet_identity.principal_id
}