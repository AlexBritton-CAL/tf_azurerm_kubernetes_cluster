data "azurerm_container_registry" "this" {
  count               = local.acr_connected
  name                = coalese(try(var.config.container_registry.name, var.container_registry.name))
  resource_group_name = coalese(try(var.config.container_registry.resource_group_name, var.container_registry.resource_group_name))
}

resource "azurerm_role_assignment" "acr_pull" {
  count                = local.acr_connected
  scope                = data.azurerm_container_registry.this[count.index].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet_identity.principal_id
}