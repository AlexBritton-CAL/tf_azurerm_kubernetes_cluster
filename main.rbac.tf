module "rbac_aks" {
  source        = "github.com/calastone/terraform-azurerm-rbac"
  resource_type = "aks"
  context       = "nonprod"
  # context = var.config.context

  default_groups  = try(var.global_config.global.RBAC.default_groups, [])
  elevated_groups = try(var.global_config.global.RBAC.elevated_groups, [])

  additional_elevated_roles = try(var.additional_elevated_roles, [])
  additional_default_roles  = try(var.additional_default_roles, [])

  resource_id = "/subscriptions/${var.global_config.global.subscription_id}/resourceGroups/${var.resource_group_name}"
}