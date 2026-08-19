module "rbac_aks" {
  source        = "github.com/calastone/terraform-azurerm-rbac"
  resource_type = "aks"
  context       = "nonprod"
  # context = var.config.context

  default_groups  = try(var.global_config.global.RBAC.default_groups, [])
  elevated_groups = try(var.global_config.global.RBAC.elevated_groups, [])

  resource_id = "/subscriptions/${var.global_config.global.subscription_id}/resourceGroups/${var.resource_group_name}"
}