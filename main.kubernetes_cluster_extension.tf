locals {
  appconfig-enabled = coalesce(try(var.config.appconfig_enabled, null), local.kube_defaults.appconfig_enabled)
}

resource "azurerm_kubernetes_cluster_extension" "app_config" {
  count                     = local.appconfig-enabled ? 1 : 0
  name           = "appconfig-extension"
  cluster_id     = azurerm_kubernetes_cluster.this.id
  extension_type = "Microsoft.AppConfiguration"
}